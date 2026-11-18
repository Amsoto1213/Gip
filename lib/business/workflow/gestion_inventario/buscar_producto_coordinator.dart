import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller de CUS-06 Buscar producto y su extensión CUS-17 Leer código de
/// producto: delega en [ServicioCatalogo].
///
/// `listarProductos` llega con la primera pantalla que lo use (DI-19).
class BuscarProductoCoordinator {
  BuscarProductoCoordinator(this._servicioCatalogo);

  final ServicioCatalogo _servicioCatalogo;

  /// Llama a servicioCatalogo.buscarPorNombre(tienda, texto) (RD-08: 1 s o
  /// menos).
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) =>
      _servicioCatalogo.buscarPorNombre(tienda, texto);

  /// Llama a servicioCatalogo.buscarPorLectura(tienda, lectura); la lectura
  /// viene del lector 2D o de la cámara (CUS-17). Devuelve null si ningún
  /// producto tiene ese código.
  Future<Producto?> buscarPorLectura(Tienda tienda, String lectura) =>
      _servicioCatalogo.buscarPorLectura(tienda, lectura);
}
