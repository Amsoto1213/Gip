import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-10 Generar reporte diario: recibe la
/// operación del sistema desde la presentación y delega; no contiene reglas de
/// negocio. Solo el propietario lo genera (RNF-12). Debe responder en 5 s o
/// menos (RD-10).
class GenerarReporteDiarioCoordinator {
  GenerarReporteDiarioCoordinator(this._servicioReportes, this._servicioAcceso);

  final ServicioReportes _servicioReportes;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioReportes.generarReporteDiario(tienda, fecha). Si no es el
  /// propietario lanza `ExcepcionSoloPropietario` y no lee nada.
  Future<ReporteDiario> generarReporte(
    Tienda tienda,
    DateTime fecha,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioReportes.generarReporteDiario(tienda, fecha);
  }
}
