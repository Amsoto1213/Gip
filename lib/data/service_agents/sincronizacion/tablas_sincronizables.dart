import 'dart:convert';

import 'package:decimal/decimal.dart';

/// Cómo se guarda una columna en SQLite y cómo viaja a Supabase.
enum TipoColumna {
  /// Texto, `uuid`, enum o `date`: pasa igual.
  texto,

  /// Dinero o cantidad: TEXT en SQLite (DI-02), `numeric` en Supabase.
  numero,

  /// Fecha en UTC: texto ISO-8601 en SQLite, `timestamptz` en Supabase.
  fecha,

  /// 0 o 1 en SQLite, `boolean` en Supabase.
  booleano,

  /// Texto JSON en SQLite, `jsonb` en Supabase.
  json,
}

class ColumnaSync {
  const ColumnaSync(this.nombre, [this.tipo = TipoColumna.texto]);

  final String nombre;
  final TipoColumna tipo;

  /// Valor de SQLite → valor para el servidor.
  Object? aServidor(Object? valor) {
    if (valor == null) return null;
    return switch (tipo) {
      TipoColumna.booleano => valor == 1 || valor == true,
      TipoColumna.json => jsonDecode(valor as String),
      _ => valor,
    };
  }

  /// Valor del servidor → valor para SQLite (lo mismo que escribe drift).
  Object? aLocal(Object? valor) {
    if (valor == null) return null;
    return switch (tipo) {
      TipoColumna.numero => Decimal.parse(valor.toString()).toString(),
      TipoColumna.fecha => DateTime.parse(
        valor.toString(),
      ).toUtc().toIso8601String(),
      TipoColumna.booleano => (valor == true || valor == 1) ? 1 : 0,
      TipoColumna.json => jsonEncode(valor),
      TipoColumna.texto => valor.toString(),
    };
  }
}

/// Una tabla que se sincroniza con Supabase (DI-47). Las columnas son las que
/// existen en los dos lados; lo que solo existe en la base local (`stock_actual`
/// de `items_inventario`) va en [valoresLocales] con su valor inicial.
class TablaSincronizable {
  const TablaSincronizable(
    this.nombre,
    this.columnas, {
    this.alConflicto,
    this.valoresLocales = const {},
    this.columnaFecha,
    this.soloAlInsertar = false,
  });

  final String nombre;
  final List<ColumnaSync> columnas;

  /// Qué hacer al bajar una fila que ya existe: el final de un
  /// `INSERT ... ON CONFLICT(id)` de SQLite (la regla de choque, DA-48). Sin
  /// él, la fila que ya existe no se toca (registros de solo agregar, RNF-15).
  final String? alConflicto;

  /// Columnas que solo existen en la base local y el valor con que se crean.
  final Map<String, String> valoresLocales;

  /// Fecha del registro que usa la conciliación para saber desde cuándo mirar
  /// (CUS-23): se toma la más antigua de lo que llegó. Nula si no cuenta.
  final String? columnaFecha;

  /// Verdadero si solo se sube la fila al crearla y nunca cuando cambia
  /// (`items_inventario`: lo único que cambia es el stock, que no se sube).
  final bool soloAlInsertar;

  List<String> get nombresColumnas => [for (final c in columnas) c.nombre];

  /// `SELECT` de la fila de esta tienda para subirla.
  String get sqlLeer =>
      'SELECT ${nombresColumnas.join(', ')} FROM $nombre '
      'WHERE id = ? AND tienda_id = ?';

  /// `INSERT` con la regla de choque para aplicar una fila que bajó.
  String get sqlAplicar {
    final todas = [...nombresColumnas, ...valoresLocales.keys];
    final marcas = [
      for (final _ in columnas) '?',
      for (final v in valoresLocales.values) "'$v'",
    ];
    final cabeza =
        '${alConflicto == null ? 'INSERT OR IGNORE' : 'INSERT'} INTO $nombre '
        '(${todas.join(', ')}) VALUES (${marcas.join(', ')})';
    return alConflicto == null
        ? cabeza
        : '$cabeza ON CONFLICT(id) $alConflicto';
  }

  /// Fila de SQLite → fila para el servidor.
  FilaSql aFilaServidor(Map<String, Object?> sql) => {
    for (final c in columnas) c.nombre: c.aServidor(sql[c.nombre]),
  };

  /// Fila del servidor → valores para [sqlAplicar], en el orden de [columnas].
  List<Object?> aValoresLocales(Map<String, Object?> json) => [
    for (final c in columnas) c.aLocal(json[c.nombre]),
  ];
}

/// Una fila tal como la entrega [TablaSincronizable.aFilaServidor].
typedef FilaSql = Map<String, Object?>;

/// Compara dos fechas ISO de SQLite sin que el largo de los decimales cambie
/// el resultado ("...34.123Z" frente a "...34.123456Z"): `strftime` las lleva
/// a milisegundos.
const _masReciente =
    "strftime('%Y-%m-%d %H:%M:%f', excluded.actualizado_en) > "
    "strftime('%Y-%m-%d %H:%M:%f', ";

const _n = TipoColumna.numero;
const _f = TipoColumna.fecha;
const _b = TipoColumna.booleano;
const _j = TipoColumna.json;

/// Las tablas que se sincronizan, en orden de llaves foráneas: los padres
/// primero. Subir y bajar siguen este orden, así una fila nunca llega antes que
/// la fila de la que depende. No se sincronizan `alertas_reabastecimiento` (cada
/// equipo las calcula, DI-25), `usuarios` y `tiendas` (viven en el servidor) ni
/// el stock (se recalcula, DI-17).
const tablasSincronizables = <TablaSincronizable>[
  TablaSincronizable(
    'productos',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('codigo'),
      ColumnaSync('nombre'),
      ColumnaSync('nombre_normalizado'),
      ColumnaSync('unidad_medida'),
      ColumnaSync('precio_compra', _n),
      ColumnaSync('precio_venta', _n),
      ColumnaSync('actualizado_en', _f),
    ],
    alConflicto:
        'DO UPDATE SET codigo = excluded.codigo, nombre = excluded.nombre, '
        'nombre_normalizado = excluded.nombre_normalizado, '
        'unidad_medida = excluded.unidad_medida, '
        'precio_compra = excluded.precio_compra, '
        'precio_venta = excluded.precio_venta, '
        'actualizado_en = excluded.actualizado_en '
        'WHERE ${_masReciente}productos.actualizado_en)',
  ),
  TablaSincronizable(
    'clientes',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('nombre'),
      ColumnaSync('nombre_normalizado'),
      ColumnaSync('telefono'),
      ColumnaSync('actualizado_en', _f),
      ColumnaSync('eliminado_en', _f),
    ],
    alConflicto:
        'DO UPDATE SET nombre = excluded.nombre, '
        'nombre_normalizado = excluded.nombre_normalizado, '
        'telefono = excluded.telefono, '
        'actualizado_en = excluded.actualizado_en, '
        'eliminado_en = excluded.eliminado_en '
        'WHERE ${_masReciente}clientes.actualizado_en)',
  ),
  TablaSincronizable(
    'items_inventario',
    [ColumnaSync('id'), ColumnaSync('tienda_id'), ColumnaSync('producto_id')],
    valoresLocales: {'stock_actual': '0'},
    soloAlInsertar: true,
  ),
  TablaSincronizable('ventas', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('fecha', _f),
    ColumnaSync('total', _n),
  ]),
  TablaSincronizable('formas_pago', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('venta_id'),
    ColumnaSync('tipo'),
    ColumnaSync('monto_recibido', _n),
    ColumnaSync('cambio', _n),
    ColumnaSync('monto', _n),
    ColumnaSync('referencia'),
  ]),
  TablaSincronizable(
    'fiados',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('cliente_id'),
      ColumnaSync('monto_inicial', _n),
      ColumnaSync('saldo_pendiente', _n),
      ColumnaSync('estado'),
      ColumnaSync('fecha_inicio', _f),
    ],
    alConflicto:
        'DO UPDATE SET estado = excluded.estado, '
        'saldo_pendiente = excluded.saldo_pendiente '
        "WHERE fiados.estado <> 'ANULADO' AND "
        '(fiados.estado <> excluded.estado OR '
        'fiados.saldo_pendiente <> excluded.saldo_pendiente)',
    columnaFecha: 'fecha_inicio',
  ),
  TablaSincronizable(
    'abonos',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('fiado_id'),
      ColumnaSync('monto', _n),
      ColumnaSync('fecha', _f),
      ColumnaSync('medio'),
      ColumnaSync('referencia'),
      ColumnaSync('anulado', _b),
    ],
    alConflicto:
        'DO UPDATE SET anulado = 1 '
        'WHERE excluded.anulado = 1 AND abonos.anulado = 0',
    columnaFecha: 'fecha',
  ),
  TablaSincronizable(
    'cajas',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('fecha'),
      ColumnaSync('base_apertura', _n),
      ColumnaSync('cerrada', _b),
      ColumnaSync('efectivo_contado', _n),
      ColumnaSync('diferencia', _n),
      ColumnaSync('fecha_cierre', _f),
    ],
    alConflicto:
        'DO UPDATE SET cerrada = excluded.cerrada, '
        'efectivo_contado = excluded.efectivo_contado, '
        'diferencia = excluded.diferencia, '
        'fecha_cierre = excluded.fecha_cierre '
        'WHERE excluded.cerrada = 1 AND (cajas.cerrada = 0 OR '
        'cajas.diferencia IS NOT excluded.diferencia OR '
        'cajas.efectivo_contado IS NOT excluded.efectivo_contado)',
  ),
  TablaSincronizable('movimientos_caja', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('caja_id'),
    ColumnaSync('tipo'),
    ColumnaSync('clasificacion'),
    ColumnaSync('valor', _n),
    ColumnaSync('descripcion'),
    ColumnaSync('fecha', _f),
  ], columnaFecha: 'fecha'),
  TablaSincronizable(
    'movimientos_inventario',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('item_id'),
      ColumnaSync('tipo'),
      ColumnaSync('cantidad', _n),
      ColumnaSync('fecha', _f),
      ColumnaSync('estado'),
      ColumnaSync('costo_unitario', _n),
      ColumnaSync('numero_factura'),
      ColumnaSync('venta_id'),
      ColumnaSync('precio_unitario', _n),
      ColumnaSync('motivo'),
      ColumnaSync('cantidad_contada', _n),
    ],
    alConflicto:
        'DO UPDATE SET estado = excluded.estado '
        "WHERE movimientos_inventario.estado <> 'ANULADO' AND "
        'movimientos_inventario.estado <> excluded.estado',
    columnaFecha: 'fecha',
  ),
  TablaSincronizable('codigos_producto', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('producto_id'),
    ColumnaSync('formato'),
    ColumnaSync('valor'),
    ColumnaSync('creado_en', _f),
  ]),
  TablaSincronizable('anulaciones_venta', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('venta_id'),
    ColumnaSync('usuario_id'),
    ColumnaSync('usuario_nombre'),
    ColumnaSync('fecha', _f),
    ColumnaSync('motivo'),
  ]),
  TablaSincronizable('ventas_perdidas', [
    ColumnaSync('id'),
    ColumnaSync('tienda_id'),
    ColumnaSync('producto_id'),
    ColumnaSync('fecha', _f),
  ]),
  TablaSincronizable(
    'conflictos_sincronizacion',
    [
      ColumnaSync('id'),
      ColumnaSync('tienda_id'),
      ColumnaSync('tipo'),
      ColumnaSync('descripcion'),
      ColumnaSync('ids_registros', _j),
      ColumnaSync('etiquetas_registros', _j),
      ColumnaSync('fecha', _f),
      ColumnaSync('resuelto', _b),
    ],
    alConflicto:
        'DO UPDATE SET resuelto = 1 '
        'WHERE excluded.resuelto = 1 AND conflictos_sincronizacion.resuelto = 0',
  ),
];

/// Tabla del servidor donde queda anotado lo que se borra de verdad (un código
/// de producto, CUS-22). Se baja como una tabla más, sin columnas propias.
const tablaEliminados = 'registros_eliminados';

/// Tablas en las que un borrado local se sube y se baja (hoy solo los códigos).
const tablasConBorrado = {'codigos_producto'};

/// La tabla con ese nombre, o nulo si no se sincroniza.
TablaSincronizable? tablaSincronizable(String nombre) {
  for (final t in tablasSincronizables) {
    if (t.nombre == nombre) return t;
  }
  return null;
}
