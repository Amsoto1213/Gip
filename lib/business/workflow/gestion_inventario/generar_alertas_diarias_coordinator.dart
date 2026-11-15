import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-24 Generar alertas de reabastecimiento
/// (proceso automático, actor Tiempo): lo dispara la app en cada arranque con
/// usuario activo, sin bloquear la pantalla (DI-25), porque la
/// sincronización (CUS-23) aún no existe. IAlertaRepositorio.reemplazar evita
/// duplicados si se ejecuta varias veces el mismo día.
class GenerarAlertasDiariasCoordinator {
  GenerarAlertasDiariasCoordinator(this._servicioAlertas);

  final ServicioAlertas _servicioAlertas;

  /// Llama a servicioAlertas.generarAlertas(tienda, fecha).
  Future<void> ejecutar(Tienda tienda, DateTime fecha) async {
    await _servicioAlertas.generarAlertas(tienda, fecha);
  }
}
