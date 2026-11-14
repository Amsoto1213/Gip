import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// Coordinadores del módulo pagos.
typedef CoordinadoresPagos = ({RegistrarVentaCoordinator registrarVenta});

/// Arma el módulo de pagos. Recibe los servicios de inventario y caja ya
/// armados y la misma unidad de trabajo, para que la venta, sus salidas y el
/// ingreso en caja vayan en una sola transacción (RNF-04, DA-53).
///
/// Procesadores: contado y Nequi; `ProcesadorFiado` llega con CUS-07.
CoordinadoresPagos registrarPagos(
  BaseLocalDrift base,
  UnidadTrabajoDrift unidadTrabajo,
  ServicioInventario servicioInventario,
  ServicioCaja servicioCaja,
) {
  final servicioVentas = ServicioVentas(
    servicioInventario,
    [ProcesadorPagoContado(servicioCaja), ProcesadorNequi()],
    VentaRepositorioDrift(base),
    unidadTrabajo,
  );
  return (registrarVenta: RegistrarVentaCoordinator(servicioVentas));
}
