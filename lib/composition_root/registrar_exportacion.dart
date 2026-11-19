import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_exportacion.dart';
import 'package:gip/business/workflow/info_tienda/exportar_datos_coordinator.dart';
import 'package:gip/data/helpers/exportador_csv_excel.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// Arma la exportación de datos del negocio (CUS-16): [ServicioExportacion]
/// con los repositorios drift y [ExportadorCsvExcel] (DI-41).
ExportarDatosCoordinator registrarExportacion(
  BaseLocalDrift base,
  ServicioAcceso servicioAcceso,
) => ExportarDatosCoordinator(
  ServicioExportacion(
    InventarioRepositorioDrift(base),
    VentaRepositorioDrift(base),
    FiadoRepositorioDrift(base),
    ExportadorCsvExcel(),
  ),
  servicioAcceso,
);
