import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';

import 'fakes_catalogo.dart';

/// Historial de movimientos en memoria, por tienda y en orden de llegada.
class MovimientoRepositorioFalso
    implements IMovimientoInventarioRepositorio, Restaurable {
  final Map<String, List<MovimientoInventario>> datos = {};
  Map<String, List<MovimientoInventario>> _copia = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  List<MovimientoInventario> de(Tienda t) =>
      datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: List.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  @override
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(movimiento);
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

  @override
  Future<DateTime?> buscarFechaPrimerMovimiento(ItemInventario item) async {
    final fechas = _delItem(item).map((m) => m.getFecha()).toList()..sort();
    return fechas.firstOrNull;
  }
}
