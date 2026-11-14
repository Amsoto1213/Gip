import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los ítems de
/// inventario; la Data Layer lo implementa (RNF-08).
abstract interface class IInventarioRepositorio {
  /// Ítem de inventario del producto en la tienda.
  Future<ItemInventario?> buscarItem(Tienda tienda, Producto producto);

  /// Ítems de la tienda con su producto, ordenados por nombre.
  Future<List<ItemInventario>> listarItems(Tienda tienda);

  /// Crea o actualiza el ítem.
  Future<void> guardarItem(Tienda tienda, ItemInventario item);
}
