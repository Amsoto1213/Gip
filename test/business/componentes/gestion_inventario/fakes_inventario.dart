import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';

import 'fakes_catalogo.dart';

/// Historial de movimientos en memoria, por tienda y en orden de llegada.
class MovimientoRepositorioFalso
    implements IMovimientoInventarioRepositorio, Restaurable {
  final Map<String, List<MovimientoInventario>> datos = {};
  Map<String, List<MovimientoInventario>> _copia = {};
  Map<String, EstadoMovimiento> _copiaEstados = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  List<MovimientoInventario> de(Tienda t) =>
      datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() {
    _copia = {for (final e in datos.entries) e.key: List.of(e.value)};
    _copiaEstados = {
      for (final m in datos.values.expand((l) => l)) m.getId(): m.getEstado(),
    };
  }

  @override
  void restaurar() {
    datos
      ..clear()
      ..addAll(_copia);
    for (final m in datos.values.expand((l) => l)) {
      final estado = _copiaEstados[m.getId()];
      if (estado != null) m.setEstado(estado);
    }
  }

  @override
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(movimiento);
  }

  /// Los movimientos de la tienda con fecha en `[desde, hasta)`, del más
  /// antiguo al más reciente (CUS-23).
  @override
  Future<List<MovimientoInventario>> listarPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async =>
      de(tienda)
          .where(
            (m) =>
                !m.getFecha().isBefore(desde) && m.getFecha().isBefore(hasta),
          )
          .toList()
        ..sort((a, b) {
          final porFecha = a.getFecha().compareTo(b.getFecha());
          return porFecha != 0 ? porFecha : a.getId().compareTo(b.getId());
        });

  /// Movimientos guardados con actualizarEstado, en orden de llegada.
  final List<MovimientoInventario> estadosActualizados = [];

  /// Si es verdadero, actualizarEstado falla (para probar el rollback).
  bool fallarActualizarEstado = false;

  @override
  Future<void> actualizarEstado(
    Tienda tienda,
    MovimientoInventario movimiento,
  ) async {
    if (fallarActualizarEstado) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    estadosActualizados.add(movimiento);
  }

  /// Las salidas de las ventas dadas, en cualquier estado.
  @override
  Future<List<SalidaVenta>> listarSalidasPorVentas(
    Tienda tienda,
    List<Venta> ventas,
  ) async {
    final ids = ventas.map((v) => v.getId()).toSet();
    return de(tienda)
        .whereType<SalidaVenta>()
        .where((s) => ids.contains(s.getVentaId()))
        .toList();
  }

  /// La más reciente por fecha entre las VIGENTES del ítem (DI-20).
  @override
  Future<EntradaMercancia?> buscarUltimaEntrada(ItemInventario item) async {
    final entradas =
        datos.values
            .expand((l) => l)
            .whereType<EntradaMercancia>()
            .where(
              (e) =>
                  e.getItem().getId() == item.getId() &&
                  e.getEstado() == EstadoMovimiento.vigente,
            )
            .toList()
          ..sort((a, b) => b.getFecha().compareTo(a.getFecha()));
    return entradas.firstOrNull;
  }

  Iterable<MovimientoInventario> _delItem(ItemInventario item) => datos.values
      .expand((l) => l)
      .where((m) => m.getItem().getId() == item.getId());

  /// Todos los del ítem, en cualquier estado, con fecha en `[desde, hasta)`,
  /// del más reciente al más antiguo (CUS-25).
  @override
  Future<List<MovimientoInventario>> listarPorItem(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  ) async =>
      _delItem(item)
          .where(
            (m) =>
                !m.getFecha().isBefore(desde) && m.getFecha().isBefore(hasta),
          )
          .toList()
        ..sort((a, b) => b.getFecha().compareTo(a.getFecha()));

  /// VIGENTES del ítem con fecha en `[desde, hasta)` (DI-25).
  @override
  Future<List<SalidaVenta>> listarSalidas(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  ) async => _delItem(item)
      .whereType<SalidaVenta>()
      .where(
        (s) =>
            s.getEstado() == EstadoMovimiento.vigente &&
            !s.getFecha().isBefore(desde) &&
            s.getFecha().isBefore(hasta),
      )
      .toList();

  /// VIGENTES de la tienda con fecha en `[desde, hasta)` (CUS-09, DI-28).
  @override
  Future<List<SalidaVenta>> listarSalidasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => de(tienda)
      .whereType<SalidaVenta>()
      .where(
        (s) =>
            s.getEstado() == EstadoMovimiento.vigente &&
            !s.getFecha().isBefore(desde) &&
            s.getFecha().isBefore(hasta),
      )
      .toList();

  /// Entradas VIGENTES de la tienda con fecha en `[desde, hasta)` (CUS-10).
  @override
  Future<List<EntradaMercancia>> listarEntradasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => de(tienda)
      .whereType<EntradaMercancia>()
      .where(
        (e) =>
            e.getEstado() == EstadoMovimiento.vigente &&
            !e.getFecha().isBefore(desde) &&
            e.getFecha().isBefore(hasta),
      )
      .toList();

  /// Los de la tienda con esos ids, en cualquier estado (CUS-22).
  @override
  Future<List<MovimientoInventario>> buscarPorIds(
    Tienda tienda,
    List<String> ids,
  ) async => de(tienda).where((m) => ids.contains(m.getId())).toList();

  @override
  Future<DateTime?> buscarFechaPrimerMovimiento(ItemInventario item) async {
    final fechas = _delItem(item).map((m) => m.getFecha()).toList()..sort();
    return fechas.firstOrNull;
  }
}
