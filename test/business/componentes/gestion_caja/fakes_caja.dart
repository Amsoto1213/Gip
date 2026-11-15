import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';

import '../gestion_inventario/fakes_catalogo.dart';

/// Cajas y movimientos en memoria. Como una base de datos: guarda los
/// movimientos aparte y arma una caja nueva en cada búsqueda.
class CajaRepositorioFalso implements ICajaRepositorio, Restaurable {
  /// Por tienda: id de caja → fecha.
  final Map<String, Map<String, DateTime>> cajas = {};

  /// Por tienda: (id de caja, movimiento) en orden de llegada.
  final Map<String, List<(String, MovimientoCaja)>> movimientos = {};

  Map<String, Map<String, DateTime>> _copiaCajas = {};
  Map<String, List<(String, MovimientoCaja)>> _copiaMovs = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  /// Si es verdadero, registrarMovimiento falla (para probar el rollback).
  bool fallar = false;

  List<MovimientoCaja> movimientosDe(Tienda t) =>
      (movimientos[t.getId()] ?? []).map((e) => e.$2).toList();

  @override
  void tomarCopia() {
    _copiaCajas = {for (final e in cajas.entries) e.key: Map.of(e.value)};
    _copiaMovs = {for (final e in movimientos.entries) e.key: List.of(e.value)};
  }

  @override
  void restaurar() {
    cajas
      ..clear()
      ..addAll(_copiaCajas);
    movimientos
      ..clear()
      ..addAll(_copiaMovs);
  }

  @override
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha) async {
    final entrada = (cajas[tienda.getId()] ?? {}).entries
        .where((e) => e.value == fecha)
        .firstOrNull;
    if (entrada == null) return null;
    final caja = Caja(entrada.key, entrada.value);
    for (final (idCaja, m)
        in movimientos[tienda.getId()] ?? const <(String, MovimientoCaja)>[]) {
      if (idCaja == caja.getId()) caja.registrarMovimiento(m);
    }
    return caja;
  }

  @override
  Future<void> crear(Tienda tienda, Caja caja) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    cajas
        .putIfAbsent(tienda.getId(), () => {})
        .putIfAbsent(caja.getId(), () => caja.getFecha());
  }

  @override
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  ) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    movimientos.putIfAbsent(tienda.getId(), () => []).add((
      caja.getId(),
      movimiento,
    ));
  }

  @override
  Future<List<MovimientoCaja>> listarMovimientos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => movimientosDe(tienda)
      .where(
        (m) => !m.getFecha().isBefore(desde) && m.getFecha().isBefore(hasta),
      )
      .toList();
}
