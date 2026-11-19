import 'package:gip/business/entidades/info_tienda/datos_exportacion.dart';

/// Protected Variations: genera el archivo CSV o Excel con los datos
/// exportados y lo entrega al usuario para guardarlo o compartirlo (RNF-22).
/// La Data Layer lo implementa con paquetes de Flutter; la Business Layer no
/// sabe cómo se escribe el archivo (DA-68, DI-41).
abstract interface class IExportador {
  /// Escribe el archivo en el formato de `datos.getFormato()` (una hoja o
  /// archivo para inventario, otro para ventas y otro para fiados), lo
  /// entrega y devuelve el nombre del archivo generado. En CSV, con tres
  /// archivos, devuelve el nombre base común (DI-41).
  Future<String> exportar(DatosExportacion datos);
}
