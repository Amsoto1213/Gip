import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso al historial de
/// movimientos de inventario; la Data Layer lo implementa (RNF-08).
///
/// Por ahora solo las operaciones de CUS-01; las demás de EA llegan con su
/// caso de uso (DI-20).
abstract interface class IMovimientoInventarioRepositorio {
  /// Agrega el movimiento al historial; nunca lo modifica (RF-01 a RF-04).
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento);

  /// Última entrada VIGENTE del ítem; permite comparar el costo (IE-02). Las
  /// anuladas o en revisión no cuentan (DI-20).
  Future<EntradaMercancia?> buscarUltimaEntrada(ItemInventario item);
}
