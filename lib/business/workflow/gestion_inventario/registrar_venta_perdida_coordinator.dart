import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-13 Registrar venta perdida: recibe la
/// operación desde la presentación y delega; no contiene reglas de negocio.
class RegistrarVentaPerdidaCoordinator {
  RegistrarVentaPerdidaCoordinator(this._servicioAlertas);

  final ServicioAlertas _servicioAlertas;

  /// Llama a servicioAlertas.registrarVentaPerdida(tienda, producto) y
  /// devuelve la venta perdida guardada (pasos 2 y 3).
  Future<VentaPerdida> registrarVentaPerdida(
    Tienda tienda,
    Producto producto,
  ) => _servicioAlertas.registrarVentaPerdida(tienda, producto);
}
