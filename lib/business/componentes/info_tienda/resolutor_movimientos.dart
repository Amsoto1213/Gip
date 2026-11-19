import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

/// Resuelve POSIBLE_DUPLICADO y STOCK_NEGATIVO anulando movimientos de
/// inventario (DA-66).
class ResolutorMovimientos implements ResolutorConflicto {
  ResolutorMovimientos(this._movimientos, this._servicioInventario);

  final IMovimientoInventarioRepositorio _movimientos;
  final ServicioInventario _servicioInventario;

  /// Verdadero si el tipo es POSIBLE_DUPLICADO o STOCK_NEGATIVO.
  @override
  bool admite(ConflictoSincronizacion conflicto) =>
      conflicto.getTipo() == TipoConflicto.posibleDuplicado ||
      conflicto.getTipo() == TipoConflicto.stockNegativo;

  /// Con `movimientos.buscarPorIds(tienda, conflicto.getIdsRegistros())` marca
  /// ANULADO los de [idsElegidos] y VIGENTE los que estaban EN_REVISION
  /// (`setEstado` y `movimientos.actualizarEstado`), y llama a
  /// `servicioInventario.recalcularStock(tienda, item)` una vez por cada ítem
  /// afectado. Si [idsElegidos] va vacío no anula nada: el propietario aceptó
  /// el conflicto como está, o lo corrige con un conteo (CUS-04).
  ///
  /// Un movimiento que ya estaba ANULADO y no se eligió sigue anulado: no se
  /// resucita lo que se anuló antes, por ejemplo una venta (DI-45). Los ids
  /// elegidos que no son del conflicto se ignoran. Si no aparecen todos los
  /// movimientos del conflicto lanza
  /// [ExcepcionRegistrosDelConflictoNoEncontrados] sin cambiar nada.
  @override
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    final ids = conflicto.getIdsRegistros();
    final encontrados = await _movimientos.buscarPorIds(tienda, ids);
    if (encontrados.length < ids.toSet().length) {
      throw const ExcepcionRegistrosDelConflictoNoEncontrados();
    }

    final elegidos = idsElegidos.toSet();
    final afectados = <String, ItemInventario>{};
    for (final movimiento in encontrados) {
      if (elegidos.contains(movimiento.getId())) {
        movimiento.setEstado(EstadoMovimiento.anulado);
      } else if (movimiento.getEstado() == EstadoMovimiento.enRevision) {
        movimiento.setEstado(EstadoMovimiento.vigente);
      }
      await _movimientos.actualizarEstado(tienda, movimiento);
      afectados.putIfAbsent(movimiento.getItem().getId(), movimiento.getItem);
    }
    for (final item in afectados.values) {
      await _servicioInventario.recalcularStock(tienda, item);
    }
  }
}
