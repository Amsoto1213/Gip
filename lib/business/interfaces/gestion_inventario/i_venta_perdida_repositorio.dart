import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a las ventas
/// perdidas; la Data Layer lo implementa (RNF-08).
///
/// Solo agrega: una venta perdida nunca se modifica ni se borra (RNF-15, DI-30).
abstract interface class IVentaPerdidaRepositorio {
  /// Agrega la venta perdida a la tienda y su entrada a la cola de
  /// sincronización (CUS-13). Dos registros del mismo producto no se pisan.
  Future<void> guardar(Tienda tienda, VentaPerdida ventaPerdida);

  /// Ventas perdidas de la tienda entre las dos fechas; las muestra el panel
  /// de alertas (RF-12).
  Future<List<VentaPerdida>> buscarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Ventas perdidas de un producto entre las dos fechas; alimentan el
  /// consumo promedio (RF-12).
  Future<List<VentaPerdida>> listarPorProducto(
    Producto producto,
    DateTime desde,
    DateTime hasta,
  );
}
