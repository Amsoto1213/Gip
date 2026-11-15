import 'package:gip/business/componentes/gestion_inventario/consumo_promedio_simple.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/alerta_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/venta_perdida_repositorio_drift.dart';
import 'package:gip/transversal/configuracion/configuracion_alertas.dart';

/// Coordinadores de las alertas de reabastecimiento (CUS-24 y CUS-05).
typedef CoordinadoresAlertas = ({
  GenerarAlertasDiariasCoordinator generarAlertas,
  ConsultarAlertasCoordinator consultarAlertas,
});

/// Arma [ServicioAlertas] con la estrategia [ConsumoPromedioSimple] y el
/// umbral de [ConfiguracionAlertas] (DI-25).
CoordinadoresAlertas registrarAlertas(
  BaseLocalDrift base,
  ServicioAcceso servicioAcceso,
) {
  final servicioAlertas = ServicioAlertas(
    InventarioRepositorioDrift(base),
    MovimientoInventarioRepositorioDrift(base),
    VentaPerdidaRepositorioDrift(base),
    AlertaRepositorioDrift(base),
    ConsumoPromedioSimple(),
    ConfiguracionAlertas.umbralDiasCobertura,
  );
  return (
    generarAlertas: GenerarAlertasDiariasCoordinator(servicioAlertas),
    consultarAlertas: ConsultarAlertasCoordinator(
      servicioAlertas,
      servicioAcceso,
    ),
  );
}
