import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_abono_excedido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_caja_cerrada.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_codigo_repetido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_movimientos.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/info_tienda/conflicto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';

/// Arma la revisión de conflictos de sincronización (CUS-22): el
/// [ServicioConciliacion] con los cuatro resolutores, uno por cada forma de
/// resolver un tipo de conflicto (DA-66, DI-45).
RevisarConflictosCoordinator registrarConciliacion(
  BaseLocalDrift base,
  IUnidadTrabajo unidadTrabajo,
  ServicioInventario servicioInventario,
  ServicioCaja servicioCaja,
  ServicioAcceso servicioAcceso,
) => RevisarConflictosCoordinator(
  ServicioConciliacion(ConflictoRepositorioDrift(base), unidadTrabajo, [
    ResolutorMovimientos(
      MovimientoInventarioRepositorioDrift(base),
      servicioInventario,
    ),
    ResolutorAbonoExcedido(FiadoRepositorioDrift(base), servicioCaja),
    ResolutorCodigoRepetido(ProductoRepositorioDrift(base)),
    ResolutorCajaCerrada(CajaRepositorioDrift(base)),
  ]),
  servicioAcceso,
);
