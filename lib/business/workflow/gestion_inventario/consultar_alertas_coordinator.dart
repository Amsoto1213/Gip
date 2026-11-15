import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-05 Consultar alertas de reabastecimiento:
/// recibe las operaciones del sistema desde la presentación y delega; no
/// contiene reglas de negocio. Solo el propietario consulta (RNF-12).
class ConsultarAlertasCoordinator {
  ConsultarAlertasCoordinator(this._servicioAlertas, this._servicioAcceso);

  final ServicioAlertas _servicioAlertas;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioAlertas.obtenerAlertas(tienda, fecha) (RNF-02). Si no es el
  /// propietario lanza `ExcepcionSoloPropietario`.
  Future<List<AlertaReabastecimiento>> consultarAlertas(
    Tienda tienda,
    DateTime fecha,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioAlertas.obtenerAlertas(tienda, fecha);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioAlertas.obtenerVentasPerdidas(tienda, desde, hasta) (RF-12).
  Future<List<VentaPerdida>> consultarVentasPerdidas(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioAlertas.obtenerVentasPerdidas(tienda, desde, hasta);
  }
}
