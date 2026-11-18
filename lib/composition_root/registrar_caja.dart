import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';

/// Piezas del módulo gestion_caja que usan otros módulos.
typedef ServiciosCaja = ({ServicioCaja servicioCaja});

/// Arma el módulo de caja con sus implementaciones concretas. Por ahora solo
/// el [ServicioCaja] que usa el pago de contado (CUS-02).
ServiciosCaja registrarCaja(BaseLocalDrift base) =>
    (servicioCaja: ServicioCaja(CajaRepositorioDrift(base)));

/// Coordinadores de la caja del propietario (CUS-11; CUS-14 se suma después).
typedef CoordinadoresCaja = ({
  RegistrarMovimientoCajaCoordinator registrarMovimientoCaja,
});

/// Arma los coordinadores de la caja con el [ServicioCaja] ya creado.
CoordinadoresCaja registrarCoordinadoresCaja(
  ServicioCaja servicioCaja,
  ServicioAcceso servicioAcceso,
) => (
  registrarMovimientoCaja: RegistrarMovimientoCajaCoordinator(
    servicioCaja,
    servicioAcceso,
  ),
);
