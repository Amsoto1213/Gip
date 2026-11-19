import 'package:gip/business/entidades/info_tienda/datos_exportacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_exportador.dart';

/// Exportador que guarda lo que recibe y devuelve un nombre fijo.
class ExportadorFalso implements IExportador {
  final List<DatosExportacion> recibidos = [];
  bool fallar = false;

  @override
  Future<String> exportar(DatosExportacion datos) async {
    if (fallar) throw StateError('falla del disco');
    recibidos.add(datos);
    return 'gip-prueba.xlsx';
  }
}
