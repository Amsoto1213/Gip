import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-16 Exportar datos del negocio: recibe la
/// operación del sistema desde la presentación y delega; no contiene reglas de
/// negocio. Solo el propietario exporta (RNF-12).
class ExportarDatosCoordinator {
  ExportarDatosCoordinator(this._servicioExportacion, this._servicioAcceso);

  final ServicioExportacion _servicioExportacion;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioExportacion.exportar(tienda, desde, hasta, formato); devuelve el
  /// nombre del archivo para que la pantalla lo muestre. Si no es el
  /// propietario lanza `ExcepcionSoloPropietario`.
  Future<String> exportar(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    FormatoExportacion formato,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioExportacion.exportar(tienda, desde, hasta, formato);
  }
}
