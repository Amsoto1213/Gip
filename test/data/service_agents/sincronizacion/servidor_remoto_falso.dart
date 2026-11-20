import 'dart:async';

import 'package:gip/data/service_agents/sincronizacion/servidor_remoto.dart';
import 'package:gip/data/service_agents/sincronizacion/tablas_sincronizables.dart';

/// Servidor en memoria que se comporta como Supabase para las pruebas del
/// Sincronizador: guarda cada fila como la devolvería PostgREST (números como
/// número, fechas con `+00:00`, booleanos como `bool`), pone `sincronizado_en`
/// con un reloj que siempre avanza y aplica las MISMAS reglas de choque que los
/// disparadores de `20261121090000_sincronizacion.sql`. Si una regla cambia
/// allá, hay que cambiarla aquí.
class ServidorRemotoFalso implements ServidorRemoto {
  /// Por tabla: id → fila.
  final Map<String, Map<String, FilaRemota>> tablas = {};

  /// Cada petición, en orden: "guardar productos 3", "leer movimientos_caja"…
  final List<String> peticiones = [];

  /// Si es verdadero, toda petición falla como si no hubiera red.
  bool sinRed = false;

  /// Si no es nulo, las lecturas esperan a que se complete: sirve para
  /// escribir algo en el equipo mientras la sincronización está a medias.
  Completer<void>? puerta;

  /// Ids que el servidor rechaza (como una llave foránea o una regla de tabla).
  final Set<String> rechazar = {};

  var _reloj = DateTime.utc(2026, 11, 19, 12);

  String _marca() {
    _reloj = _reloj.add(const Duration(milliseconds: 7, microseconds: 321));
    final iso = _reloj.toIso8601String();
    // PostgREST entrega "2026-11-19T12:00:00.007321+00:00".
    return iso.replaceFirst('Z', '+00:00');
  }

  void _comprobarRed(String peticion) {
    peticiones.add(peticion);
    if (sinRed) throw const FalloDeRed('sin red');
  }

  void _comprobarRechazos(List<FilaRemota> filas) {
    for (final f in filas) {
      if (rechazar.contains(f['id'])) {
        throw RechazoDelServidor('rechazada ${f['id']}', '23503');
      }
    }
  }

  Map<String, FilaRemota> _de(String tabla) =>
      tablas.putIfAbsent(tabla, () => {});

  /// Cómo guarda PostgREST cada columna.
  FilaRemota _comoServidor(String tabla, FilaRemota fila) {
    final t = tablaSincronizable(tabla);
    final resultado = Map<String, Object?>.of(fila);
    if (t != null) {
      for (final c in t.columnas) {
        final v = resultado[c.nombre];
        if (v == null) continue;
        resultado[c.nombre] = switch (c.tipo) {
          TipoColumna.numero => num.parse(v.toString()),
          TipoColumna.fecha => DateTime.parse(
            v.toString(),
          ).toUtc().toIso8601String().replaceFirst('Z', '+00:00'),
          _ => v,
        };
      }
    }
    return resultado;
  }

  @override
  Future<void> insertarSiNoExiste(String tabla, List<FilaRemota> filas) async {
    _comprobarRed('insertar $tabla ${filas.length}');
    _comprobarRechazos(filas);
    for (final f in filas) {
      final id = '${f['id']}';
      if (_de(tabla).containsKey(id)) continue;
      _de(tabla)[id] = {
        ..._comoServidor(tabla, f),
        'sincronizado_en': _marca(),
      };
    }
  }

  @override
  Future<void> guardar(String tabla, List<FilaRemota> filas) async {
    _comprobarRed('guardar $tabla ${filas.length}');
    _comprobarRechazos(filas);
    for (final f in filas) {
      final id = '${f['id']}';
      final nueva = _comoServidor(tabla, f);
      final vieja = _de(tabla)[id];
      if (vieja == null) {
        _de(tabla)[id] = {...nueva, 'sincronizado_en': _marca()};
        continue;
      }
      final resultado = _aplicarRegla(tabla, vieja, nueva);
      if (resultado == null) continue; // la regla ignora la actualización
      _de(tabla)[id] = {...resultado, 'sincronizado_en': _marca()};
    }
  }

  /// Los disparadores `<tabla>_1_regla`. Devuelve nulo si ignoran la
  /// actualización.
  FilaRemota? _aplicarRegla(String tabla, FilaRemota vieja, FilaRemota nueva) {
    final resultado = Map<String, Object?>.of(nueva);
    switch (tabla) {
      case 'productos' || 'clientes':
        final a = DateTime.parse('${nueva['actualizado_en']}');
        final b = DateTime.parse('${vieja['actualizado_en']}');
        if (a.isBefore(b)) return null;
      case 'movimientos_inventario' || 'fiados':
        if (vieja['estado'] == 'ANULADO') resultado['estado'] = 'ANULADO';
      case 'abonos':
        resultado['anulado'] =
            vieja['anulado'] == true || nueva['anulado'] == true;
      case 'conflictos_sincronizacion':
        resultado['resuelto'] =
            vieja['resuelto'] == true || nueva['resuelto'] == true;
      case 'cajas':
        if (vieja['cerrada'] == true && nueva['cerrada'] != true) {
          return Map.of(vieja);
        }
    }
    return resultado;
  }

  @override
  Future<void> borrar(String tabla, String id) async {
    _comprobarRed('borrar $tabla $id');
    final fila = _de(tabla).remove(id);
    if (fila == null) return;
    // El disparador `codigos_producto_eliminado`.
    _de(tablaEliminados)['$tabla/$id'] = {
      'id': '$tabla/$id',
      'tienda_id': fila['tienda_id'],
      'tabla': tabla,
      'registro_id': id,
      'sincronizado_en': _marca(),
    };
  }

  @override
  Future<List<FilaRemota>> leerDesde(
    String tabla,
    String tiendaId, {
    required String? desde,
    required int limite,
    required int desplazamiento,
  }) async {
    _comprobarRed('leer $tabla');
    await puerta?.future;
    final limiteInferior = desde == null ? null : DateTime.parse(desde);
    final filas =
        [
          for (final f in _de(tabla).values)
            if (f['tienda_id'] == tiendaId &&
                (limiteInferior == null ||
                    !DateTime.parse('${f['sincronizado_en']}')
                        .isBefore(limiteInferior)))
              f,
        ]..sort((a, b) {
          final porMarca = DateTime.parse('${a['sincronizado_en']}')
              .compareTo(DateTime.parse('${b['sincronizado_en']}'));
          return porMarca != 0
              ? porMarca
              : '${a['id']}'.compareTo('${b['id']}');
        });
    return [
      for (final f in filas.skip(desplazamiento).take(limite))
        Map<String, Object?>.of(f),
    ];
  }

  /// Cuántas filas hay en la tabla (de todas las tiendas).
  int cuantas(String tabla) => _de(tabla).length;

  /// La fila con ese id, o nulo.
  FilaRemota? fila(String tabla, String id) => _de(tabla)[id];
}
