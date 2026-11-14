import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-06 Buscar producto: delega en
/// [ServicioCatalogo].
///
/// Por ahora solo la búsqueda por nombre. `buscarPorLectura` llega con CUS-17
/// y `listarProductos` con la primera pantalla que lo use (DI-19).
class BuscarProductoCoordinator {
  BuscarProductoCoordinator(this._servicioCatalogo);

  final ServicioCatalogo _servicioCatalogo;

  /// Llama a servicioCatalogo.buscarPorNombre(tienda, texto) (RD-08: 1 s o
  /// menos).
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) =>
      _servicioCatalogo.buscarPorNombre(tienda, texto);
}
