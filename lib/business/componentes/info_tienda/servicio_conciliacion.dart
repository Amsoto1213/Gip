import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/etiquetas_conflicto.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/interfaces/info_tienda/i_conflicto_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';
import 'package:uuid/uuid.dart';

/// Un choque encontrado y, si hace falta, el movimiento que queda EN_REVISION
/// cuando el conflicto es nuevo.
typedef _Hallazgo = ({
  ConflictoSincronizacion conflicto,
  MovimientoInventario? aRevisar,
});

/// Pure Fabrication e Information Expert de la conciliación: después de
/// sincronizar recalcula stock y saldos de fiados y detecta los choques que
/// debe decidir el propietario (CUS-23); también los muestra y aplica su
/// decisión (CUS-22) (RNF-08, ERS 3.2.1 c, DA-48). El saldo de caja no se
/// recalcula: `Caja` lo calcula de sus movimientos (DA-62).
///
/// Cada conflicto tiene un id determinista (tipo y registros, UUID v5), así que
/// dos equipos que detectan el mismo choque no lo duplican y repetir la
/// conciliación no crea nada nuevo. Un choque que ya existe, también si el
/// propietario ya lo resolvió, no se vuelve a crear ni a aplicar (DI-46).
class ServicioConciliacion {
  ServicioConciliacion(
    this._conflictos,
    this._movimientos,
    this._fiados,
    this._cajas,
    this._productos,
    this._servicioInventario,
    this._unidadTrabajo,
    List<ResolutorConflicto> resolutores, {
    DateTime Function()? reloj,
  }) : _resolutores = List.unmodifiable(resolutores),
       _reloj = reloj ?? DateTime.now;

  /// Cuánto antes de `desde` se buscan las entradas que pueden ser pareja de
  /// una recién llegada: la original puede ser anterior a lo que se bajó
  /// (DI-46).
  static const margenDuplicados = Duration(days: 1);

  final IConflictoRepositorio _conflictos;
  final IMovimientoInventarioRepositorio _movimientos;
  final IFiadoRepositorio _fiados;
  final ICajaRepositorio _cajas;
  final IProductoRepositorio _productos;
  final ServicioInventario _servicioInventario;
  final IUnidadTrabajo _unidadTrabajo;
  final List<ResolutorConflicto> _resolutores;
  final DateTime Function() _reloj;

  /// Dentro de `unidadTrabajo.ejecutar` llama, en este orden, a
  /// `detectarPosiblesDuplicados`, `detectarStockNegativo`,
  /// `detectarAbonosExcedidos`, `detectarCodigosRepetidos` y
  /// `detectarMovimientosCajaCerrada`; guarda cada conflicto con
  /// `conflictos.guardar` (ignora los que ya existen) y devuelve los nuevos
  /// (CUS-23, DA-48). [desde] es la fecha del registro más antiguo que llegó al
  /// sincronizar. Si algo falla no se guarda nada.
  Future<List<ConflictoSincronizacion>> conciliar(
    Tienda tienda,
    DateTime desde,
  ) async {
    final nuevos = <ConflictoSincronizacion>[];
    await _unidadTrabajo.ejecutar(() async {
      nuevos.clear();
      final ahora = _reloj().toUtc();
      nuevos.addAll(
        await _registrar(
          tienda,
          await _detectarPosiblesDuplicados(tienda, desde, ahora),
          ahora,
        ),
      );
      nuevos.addAll(
        await _registrar(
          tienda,
          await _detectarStockNegativo(tienda, desde, ahora),
          ahora,
        ),
      );
      nuevos.addAll(
        await _registrar(
          tienda,
          await _detectarAbonosExcedidos(tienda, desde, ahora),
          ahora,
        ),
      );
      nuevos.addAll(
        await _registrar(
          tienda,
          await _detectarCodigosRepetidos(tienda, ahora),
          ahora,
        ),
      );
      nuevos.addAll(
        await _registrar(
          tienda,
          await _detectarMovimientosCajaCerrada(tienda, desde, ahora),
          ahora,
        ),
      );
    });
    return nuevos;
  }

  /// Llama a conflictos.listarPendientes(tienda).
  Future<List<ConflictoSincronizacion>> obtenerConflictos(Tienda tienda) =>
      _conflictos.listarPendientes(tienda);

  /// Dentro de unidadTrabajo.ejecutar llama a
  /// `resolutorPara(conflicto).resolver(tienda, conflicto, idsElegidos)`,
  /// luego a `conflicto.setResuelto(true)` y a
  /// `conflictos.marcarResuelto(tienda, conflicto)` (DA-66). Si algo falla, no
  /// se guarda nada y el conflicto sigue sin resolver, también en memoria.
  ///
  /// Rechaza con [ExcepcionConflictoYaResuelto] un conflicto que ya estaba
  /// resuelto, para no aplicar dos veces la decisión (por ejemplo, devolver dos
  /// veces un abono), y con [ExcepcionConflictoSinResolutor] uno de un tipo que
  /// ningún resolutor atiende (DI-45).
  Future<void> resolverConflicto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    if (conflicto.isResuelto()) throw const ExcepcionConflictoYaResuelto();
    final resolutor = _resolutorPara(conflicto);
    try {
      await _unidadTrabajo.ejecutar(() async {
        await resolutor.resolver(tienda, conflicto, idsElegidos);
        conflicto.setResuelto(true);
        await _conflictos.marcarResuelto(tienda, conflicto);
      });
    } catch (_) {
      conflicto.setResuelto(false);
      rethrow;
    }
  }

  /// Recorre los resolutores y devuelve el primero cuyo `admite(conflicto)` es
  /// verdadero; rechaza si ninguno lo admite (Polymorphism).
  ResolutorConflicto _resolutorPara(ConflictoSincronizacion conflicto) {
    for (final resolutor in _resolutores) {
      if (resolutor.admite(conflicto)) return resolutor;
    }
    throw const ExcepcionConflictoSinResolutor();
  }

  /// Guarda cada hallazgo (paso 14); de los que son nuevos aplica su efecto
  /// (la segunda entrada queda EN_REVISION) y los devuelve.
  Future<List<ConflictoSincronizacion>> _registrar(
    Tienda tienda,
    List<_Hallazgo> hallazgos,
    DateTime ahora,
  ) async {
    final nuevos = <ConflictoSincronizacion>[];
    for (final h in hallazgos) {
      if (!await _conflictos.guardar(tienda, h.conflicto)) continue;
      final revisar = h.aRevisar;
      if (revisar != null) {
        revisar.setEstado(EstadoMovimiento.enRevision);
        await _movimientos.actualizarEstado(tienda, revisar);
      }
      nuevos.add(h.conflicto);
    }
    return nuevos;
  }

  /// Id determinista: UUID v5 del tipo y de las claves del choque (DA-48).
  static String _id(TipoConflicto tipo, List<String> claves) =>
      const Uuid().v5(Namespace.url.value, '${tipo.name}|${claves.join('|')}');

  ConflictoSincronizacion _conflicto(
    TipoConflicto tipo,
    List<String> claves,
    String descripcion,
    List<String> ids,
    List<String> etiquetas,
    DateTime ahora,
  ) => ConflictoSincronizacion(
    _id(tipo, claves),
    tipo,
    descripcion,
    ids,
    ahora,
    etiquetasRegistros: etiquetas,
  );

  /// Dos entradas VIGENTES con el mismo ítem, cantidad y número de factura son
  /// un posible duplicado: la segunda (por fecha) queda EN_REVISION y el
  /// propietario decide (paso 6). Sin número de factura no se comparan: dos
  /// compras iguales sin factura son normales (DI-46).
  Future<List<_Hallazgo>> _detectarPosiblesDuplicados(
    Tienda tienda,
    DateTime desde,
    DateTime ahora,
  ) async {
    final recientes = await _movimientos.listarPorTienda(
      tienda,
      desde.subtract(margenDuplicados),
      ahora,
    );
    final grupos = <String, List<EntradaMercancia>>{};
    for (final m in recientes) {
      if (m is! EntradaMercancia) continue;
      if (m.getEstado() != EstadoMovimiento.vigente) continue;
      final factura = m.getNumeroFactura()?.trim() ?? '';
      if (factura.isEmpty) continue;
      grupos
          .putIfAbsent(
            '${m.getItem().getId()}|${m.getCantidad()}|$factura',
            () => [],
          )
          .add(m);
    }
    final hallazgos = <_Hallazgo>[];
    for (final grupo in grupos.values) {
      if (grupo.length < 2) continue;
      grupo.sort((a, b) {
        final porFecha = a.getFecha().compareTo(b.getFecha());
        return porFecha != 0 ? porFecha : a.getId().compareTo(b.getId());
      });
      final primera = grupo.first;
      for (final otra in grupo.skip(1)) {
        final producto = primera.getItem().getProducto().getNombre();
        hallazgos.add((
          conflicto: _conflicto(
            TipoConflicto.posibleDuplicado,
            [primera.getId(), otra.getId()],
            'Dos entradas iguales de $producto, con la misma cantidad y '
            'factura. Puede que una se haya registrado dos veces.',
            [primera.getId(), otra.getId()],
            [
              EtiquetasConflicto.movimiento(primera),
              EtiquetasConflicto.movimiento(otra),
            ],
            ahora,
          ),
          aRevisar: otra,
        ));
      }
    }
    return hallazgos;
  }

  /// Recalcula el stock de cada ítem que recibió movimientos desde [desde]
  /// (pasos 7 a 9) y crea un conflicto por cada uno que quede negativo. El
  /// choque se identifica por el ítem: si el propietario lo acepta así, no se
  /// vuelve a avisar del mismo ítem (DI-46).
  Future<List<_Hallazgo>> _detectarStockNegativo(
    Tienda tienda,
    DateTime desde,
    DateTime ahora,
  ) async {
    final recibidos = await _movimientos.listarPorTienda(tienda, desde, ahora);
    final porItem = <String, List<MovimientoInventario>>{};
    final items = <String, ItemInventario>{};
    for (final m in recibidos) {
      final item = m.getItem();
      items.putIfAbsent(item.getId(), () => item);
      porItem.putIfAbsent(item.getId(), () => []).add(m);
    }
    final hallazgos = <_Hallazgo>[];
    for (final MapEntry(key: idItem, value: item) in items.entries) {
      final stock = await _servicioInventario.recalcularStock(tienda, item);
      if (stock >= Decimal.zero) continue;
      final delItem = porItem[idItem]!;
      final vigentes = [
        for (final m in delItem)
          if (m.getEstado() == EstadoMovimiento.vigente) m,
      ];
      final causas = vigentes.isEmpty ? delItem : vigentes;
      final producto = item.getProducto().getNombre();
      hallazgos.add((
        conflicto: _conflicto(
          TipoConflicto.stockNegativo,
          [idItem],
          '$producto quedó con existencia negativa: '
          '${EtiquetasConflicto.cantidad(stock)}. Cuente el producto o '
          'revise estos movimientos.',
          [for (final m in causas) m.getId()],
          [for (final m in causas) EtiquetasConflicto.movimiento(m)],
          ahora,
        ),
        aRevisar: null,
      ));
    }
    return hallazgos;
  }

  /// Recalcula el saldo de los fiados con cambios desde [desde] y lo guarda si
  /// cambió (paso 10); si queda negativo, los abonos suman más que el fiado.
  Future<List<_Hallazgo>> _detectarAbonosExcedidos(
    Tienda tienda,
    DateTime desde,
    DateTime ahora,
  ) async {
    final hallazgos = <_Hallazgo>[];
    for (final fiado in await _fiados.listarModificadosDesde(tienda, desde)) {
      if (fiado.getEstado() == EstadoFiado.anulado) continue;
      final saldoAntes = fiado.getSaldoPendiente();
      final estadoAntes = fiado.getEstado();
      fiado.recalcularSaldo();
      if (fiado.getSaldoPendiente() != saldoAntes ||
          fiado.getEstado() != estadoAntes) {
        await _fiados.actualizarSaldo(tienda, fiado);
      }
      if (fiado.getSaldoPendiente() >= Decimal.zero) continue;
      final abonos = [
        for (final a in fiado.getAbonos())
          if (!a.isAnulado()) a,
      ];
      final cliente = fiado.getCliente().getNombre();
      final sumaAbonos = abonos.fold(
        Decimal.zero,
        (suma, a) => suma + a.getMonto(),
      );
      hallazgos.add((
        conflicto: _conflicto(
          TipoConflicto.abonoExcedeSaldo,
          [fiado.getId(), ...abonos.map((a) => a.getId())],
          'Los abonos de $cliente suman '
          '${EtiquetasConflicto.pesos(sumaAbonos)} y el fiado era de '
          '${EtiquetasConflicto.pesos(fiado.getMontoInicial())}.',
          [fiado.getId(), ...abonos.map((a) => a.getId())],
          [
            'Fiado de $cliente por '
                '${EtiquetasConflicto.pesos(fiado.getMontoInicial())}',
            for (final a in abonos) EtiquetasConflicto.abono(a),
          ],
          ahora,
        ),
        aRevisar: null,
      ));
    }
    return hallazgos;
  }

  /// Un código de barras o QR en dos productos, o un código interno repetido
  /// (paso 11). Mira todos los productos de la tienda: son pocos y la regla de
  /// no repetir solo se valida en cada equipo por separado (DI-46).
  Future<List<_Hallazgo>> _detectarCodigosRepetidos(
    Tienda tienda,
    DateTime ahora,
  ) async {
    final productos = await _productos.listar(tienda);
    final internos = <String, List<Producto>>{};
    final lecturas = <String, List<Producto>>{};
    for (final p in productos) {
      final interno = p.getCodigo().trim();
      if (interno.isNotEmpty) internos.putIfAbsent(interno, () => []).add(p);
      final vistos = <String>{};
      for (final c in p.getCodigos()) {
        final valor = c.getValor().trim();
        if (valor.isNotEmpty && vistos.add(valor)) {
          lecturas.putIfAbsent(valor, () => []).add(p);
        }
      }
    }
    final hallazgos = <_Hallazgo>[];
    for (final (clase, grupos) in [
      ('interno', internos),
      ('lectura', lecturas),
    ]) {
      for (final MapEntry(key: valor, value: lista) in grupos.entries) {
        if (lista.length < 2) continue;
        final ordenados = [...lista]
          ..sort((a, b) => a.getId().compareTo(b.getId()));
        final nombres = ordenados.map((p) => p.getNombre()).join(' y ');
        hallazgos.add((
          conflicto: _conflicto(
            TipoConflicto.codigoRepetido,
            [clase, valor, ...ordenados.map((p) => p.getId())],
            clase == 'interno'
                ? 'El código interno $valor está en más de un producto: '
                      '$nombres.'
                : 'El código $valor está en más de un producto: $nombres.',
            [for (final p in ordenados) p.getId()],
            [for (final p in ordenados) '${p.getNombre()} · código $valor'],
            ahora,
          ),
          aRevisar: null,
        ));
      }
    }
    return hallazgos;
  }

  /// Un movimiento de caja posterior al cierre de su caja (paso 12): llegó de
  /// otro equipo cuando la caja ya estaba cerrada. Solo mira los movimientos
  /// con fecha posterior al cierre; uno hecho antes del cierre y recibido
  /// después no se detecta (DI-46).
  Future<List<_Hallazgo>> _detectarMovimientosCajaCerrada(
    Tienda tienda,
    DateTime desde,
    DateTime ahora,
  ) async {
    final cajasPorDia = <DateTime, Caja?>{};
    final hallazgos = <_Hallazgo>[];
    for (final m in await _cajas.listarMovimientos(tienda, desde, ahora)) {
      final local = m.getFecha().toLocal();
      final dia = DateTime(local.year, local.month, local.day);
      if (!cajasPorDia.containsKey(dia)) {
        cajasPorDia[dia] = await _cajas.buscarPorFecha(tienda, dia);
      }
      final caja = cajasPorDia[dia];
      final cierre = caja?.getFechaCierre();
      if (caja == null || cierre == null || !cierre.isBefore(m.getFecha())) {
        continue;
      }
      final nombreCaja =
          'Caja del ${dia.day.toString().padLeft(2, '0')}/'
          '${dia.month.toString().padLeft(2, '0')}';
      hallazgos.add((
        conflicto: _conflicto(
          TipoConflicto.movimientoCajaCerrada,
          [caja.getId(), m.getId()],
          'Llegó un movimiento de ${EtiquetasConflicto.pesos(m.getValor())} '
          '(${m.getDescripcion()}) a la $nombreCaja, que ya estaba cerrada.',
          [caja.getId(), m.getId()],
          [
            nombreCaja,
            '${m.esIngreso() ? 'Ingreso' : 'Egreso'} de '
                '${EtiquetasConflicto.pesos(m.getValor())} · '
                '${m.getDescripcion()} · '
                '${EtiquetasConflicto.diaYHora(m.getFecha())}',
          ],
          ahora,
        ),
        aRevisar: null,
      ));
    }
    return hallazgos;
  }
}
