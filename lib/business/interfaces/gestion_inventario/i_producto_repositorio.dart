import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a datos del
/// catálogo; la Data Layer lo implementa (RNF-08).
abstract interface class IProductoRepositorio {
  /// Coincidencia parcial sobre el nombre normalizado (sin mayúsculas ni
  /// tildes) que guarda la base de datos (RF-06, RD-08).
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto);

  /// Producto por su código interno; se usa para validar que no se repita al
  /// crearlo.
  Future<Producto?> buscarPorCodigo(Tienda tienda, String codigo);

  /// Producto que tiene asociado ese código (de barras o QR); compara el texto
  /// exacto de la lectura.
  Future<Producto?> buscarPorCodigoProducto(Tienda tienda, String valor);

  /// Catálogo de la tienda ordenado por nombre (RNF-13).
  Future<List<Producto>> listar(Tienda tienda);

  /// Crea o actualiza el producto, identificado por su id, con sus códigos.
  Future<void> guardar(Tienda tienda, Producto producto);

  /// Códigos cuyo valor quedó asociado a más de un producto de la tienda al
  /// sincronizar.
  Future<List<CodigoProducto>> listarCodigosRepetidos(Tienda tienda);

  /// Producto con sus códigos, o null.
  Future<Producto?> buscarPorId(Tienda tienda, String id);

  /// Borra ese código del producto. [guardar] nunca borra códigos (un producto
  /// leído por otro repositorio llega sin ellos), así que quitar uno tiene su
  /// propia operación (CUS-22, DI-34, DI-45). Se une a la transacción abierta.
  Future<void> quitarCodigo(
    Tienda tienda,
    Producto producto,
    CodigoProducto codigo,
  );
}
