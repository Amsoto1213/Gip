import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';

/// Piezas del módulo gestion_caja que usan otros módulos.
typedef ServiciosCaja = ({ServicioCaja servicioCaja});

/// Arma el módulo de caja con sus implementaciones concretas. Por ahora solo
/// el [ServicioCaja] que usa el pago de contado (CUS-02); sus coordinadores
/// llegan con CUS-11 y CUS-14.
ServiciosCaja registrarCaja(BaseLocalDrift base) =>
    (servicioCaja: ServicioCaja(CajaRepositorioDrift(base)));
