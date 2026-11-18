import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-18 Gestionar producto (extiende a CUS-06):
/// delega en [ServicioCatalogo], una llamada por operación (DA-67).
///
/// Crear, editar, asociar código e imprimir etiquetas.
class GestionarProductoCoordinator {
  GestionarProductoCoordinator(this._servicioCatalogo);

  final ServicioCatalogo _servicioCatalogo;

  /// Llama a servicioCatalogo.crearProducto (IE-05 g).
  Future<Producto> crearProducto(
    Tienda tienda,
    String codigo,
    String nombre,
    UnidadMedida unidad,
    Decimal? precioCompra,
    Decimal precioVenta,
  ) => _servicioCatalogo.crearProducto(
    tienda,
    codigo,
    nombre,
    unidad,
    precioCompra,
    precioVenta,
  );

  /// Llama a servicioCatalogo.asociarCodigo(tienda, producto, valor) (CUS-18,
  /// opt "Asociar código").
  Future<CodigoProducto> asociarCodigo(
    Tienda tienda,
    Producto producto,
    String valor,
  ) => _servicioCatalogo.asociarCodigo(tienda, producto, valor);

  /// Llama a servicioCatalogo.editarProducto.
  Future<void> editarProducto(
    Tienda tienda,
    Producto producto,
    String nombre,
    UnidadMedida unidad,
    Decimal? precioCompra,
    Decimal precioVenta,
  ) => _servicioCatalogo.editarProducto(
    tienda,
    producto,
    nombre,
    unidad,
    precioCompra,
    precioVenta,
  );

  /// Llama a servicioCatalogo.imprimirEtiquetas (CUS-18, opt "Etiquetas").
  Future<void> imprimirEtiquetas(
    Tienda tienda,
    List<Producto> productos,
    int copias,
  ) => _servicioCatalogo.imprimirEtiquetas(tienda, productos, copias);
}
