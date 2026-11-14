import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-03 Registrar pérdida o devolución al
/// proveedor: recibe las operaciones del sistema desde la presentación y
/// delega en [ServicioInventario]; no contiene reglas de negocio.
class RegistrarPerdidaCoordinator {
  RegistrarPerdidaCoordinator(this._servicioInventario);

  final ServicioInventario _servicioInventario;

  /// Existencia actual del producto en la tienda, para mostrar "Hay N" y
  /// "Quedará en" antes de confirmar (DI-22). Llama a
  /// servicioInventario.obtenerItem y devuelve su stock.
  Future<Decimal> consultarExistencia(Tienda tienda, Producto producto) async =>
      (await _servicioInventario.obtenerItem(
        tienda,
        producto,
      )).getStockActual();

  /// Llama a servicioInventario.registrarMerma y devuelve la merma; el nuevo
  /// stock se lee en `merma.getItem().getStockActual()`.
  Future<Merma> registrarPerdida(
    Tienda tienda,
    Producto producto,
    Decimal cantidad,
    MotivoMerma? motivo,
  ) => _servicioInventario.registrarMerma(tienda, producto, cantidad, motivo);
}
