import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-25 Consultar existencias (actor Empleado):
/// muestra los productos con su stock y el historial de movimientos de cada
/// uno (CUN-03, DA-50). Delega en [ServicioInventario]; no contiene reglas de
/// negocio. Funciona sin conexión sobre la base local (RNF-08).
class ConsultarExistenciasCoordinator {
  ConsultarExistenciasCoordinator(this._servicioInventario);

  final ServicioInventario _servicioInventario;

  /// Llama a servicioInventario.listarExistencias: cada ítem con su producto
  /// y su stock actual, ordenados por nombre (pasos 2 a 7).
  Future<List<ItemInventario>> listarExistencias(Tienda tienda) =>
      _servicioInventario.listarExistencias(tienda);

  /// Llama a servicioInventario.consultarMovimientos: el historial del
  /// producto con fecha en `[desde, hasta)`, del más reciente al más antiguo
  /// (opt Historial, pasos 10 a 17).
  Future<List<MovimientoInventario>> consultarMovimientos(
    Tienda tienda,
    Producto producto,
    DateTime desde,
    DateTime hasta,
  ) => _servicioInventario.consultarMovimientos(tienda, producto, desde, hasta);
}
