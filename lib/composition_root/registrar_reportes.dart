import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_margen_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/data/service_agents/estado_sincronizacion_drift.dart';

/// Coordinadores de los reportes del propietario (CUS-09; CUS-10, CUS-11 y
/// CUS-12 se suman después).
typedef CoordinadoresReportes = ({ConsultarMargenCoordinator consultarMargen});

/// Arma [ServicioReportes] con lo que necesitan el margen de ganancia y el
/// reporte diario (DI-28, DI-29).
CoordinadoresReportes registrarReportes(
  BaseLocalDrift base,
  ServicioAcceso servicioAcceso,
) {
  final servicioReportes = ServicioReportes(
    VentaRepositorioDrift(base),
    MovimientoInventarioRepositorioDrift(base),
    CajaRepositorioDrift(base),
    FiadoRepositorioDrift(base),
    EstadoSincronizacionDrift(base),
  );
  return (
    consultarMargen: ConsultarMargenCoordinator(
      servicioReportes,
      servicioAcceso,
    ),
  );
}
