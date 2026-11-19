import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_abono_excedido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_caja_cerrada.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_codigo_repetido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_movimientos.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/workflow/info_tienda/conciliar_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/info_tienda/conflicto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';

/// Los dos casos de uso de la conciliación: revisar y resolver los conflictos
/// (CUS-22) y detectarlos al sincronizar (CUS-23).
typedef Conciliacion = ({
  RevisarConflictosCoordinator revisarConflictos,
  ConciliarCoordinator conciliar,
});

/// Arma el [ServicioConciliacion] con los cuatro resolutores, uno por cada
/// forma de resolver un tipo de conflicto (DA-66, DI-45), y los coordinadores
/// de CUS-22 y CUS-23 (DI-46).
Conciliacion registrarConciliacion(
  BaseLocalDrift base,
  IUnidadTrabajo unidadTrabajo,
  ServicioInventario servicioInventario,
  ServicioCaja servicioCaja,
  ServicioAcceso servicioAcceso,
) {
  final movimientos = MovimientoInventarioRepositorioDrift(base);
  final fiados = FiadoRepositorioDrift(base);
  final cajas = CajaRepositorioDrift(base);
  final productos = ProductoRepositorioDrift(base);
  final servicio = ServicioConciliacion(
    ConflictoRepositorioDrift(base),
    movimientos,
    fiados,
    cajas,
    productos,
    servicioInventario,
    unidadTrabajo,
    [
      ResolutorMovimientos(movimientos, servicioInventario),
      ResolutorAbonoExcedido(fiados, servicioCaja),
      ResolutorCodigoRepetido(productos),
      ResolutorCajaCerrada(cajas),
    ],
  );
  return (
    revisarConflictos: RevisarConflictosCoordinator(servicio, servicioAcceso),
    conciliar: ConciliarCoordinator(servicio),
  );
}
