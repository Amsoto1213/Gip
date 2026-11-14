import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';

/// Relleno hasta CUS-01 (DI-15). Lo reemplaza
/// `MovimientoInventarioRepositorioDrift`.
class MovimientoInventarioRepositorioPendiente
    implements IMovimientoInventarioRepositorio {
  const MovimientoInventarioRepositorioPendiente();

  @override
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento) =>
      throw UnsupportedError(
        'Movimientos de inventario no disponibles todavía',
      );

  @override
  Future<EntradaMercancia?> buscarUltimaEntrada(ItemInventario item) =>
      throw UnsupportedError(
        'Movimientos de inventario no disponibles todavía',
      );
}
