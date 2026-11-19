import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/workflow/pagos/anular_venta_coordinator.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// Coordinadores del módulo pagos.
typedef CoordinadoresPagos = ({
  RegistrarVentaCoordinator registrarVenta,
  RegistrarFiadoCoordinator registrarFiado,
  RegistrarAbonoCoordinator registrarAbono,
  ConsultarClienteCoordinator consultarCliente,
  ServicioVentas servicioVentas,
});

/// Arma el módulo de pagos. Recibe los servicios de inventario y caja ya
/// armados y la misma unidad de trabajo, para que la venta, sus salidas, el
/// ingreso en caja y el fiado vayan en una sola transacción (RNF-04, DA-53).
CoordinadoresPagos registrarPagos(
  BaseLocalDrift base,
  UnidadTrabajoDrift unidadTrabajo,
  ServicioInventario servicioInventario,
  ServicioCaja servicioCaja,
) {
  final fiados = FiadoRepositorioDrift(base);
  final servicioFiados = ServicioFiados(fiados);
  final servicioClientes = ServicioClientes(ClienteRepositorioDrift(base));
  final servicioVentas = ServicioVentas(
    servicioInventario,
    [
      ProcesadorPagoContado(servicioCaja),
      ProcesadorNequi(),
      ProcesadorFiado(servicioFiados),
    ],
    VentaRepositorioDrift(base),
    unidadTrabajo,
  );
  return (
    registrarVenta: RegistrarVentaCoordinator(servicioVentas),
    registrarFiado: RegistrarFiadoCoordinator(servicioClientes, servicioFiados),
    registrarAbono: RegistrarAbonoCoordinator(
      ServicioAbonos(fiados, servicioCaja, unidadTrabajo),
    ),
    consultarCliente: ConsultarClienteCoordinator(
      servicioClientes,
      servicioFiados,
    ),
    servicioVentas: servicioVentas,
  );
}

/// Coordinador de la anulación de ventas del propietario (CUS-20), con el
/// [ServicioVentas] ya armado.
AnularVentaCoordinator registrarAnularVenta(
  ServicioVentas servicioVentas,
  ServicioAcceso servicioAcceso,
) => AnularVentaCoordinator(servicioVentas, servicioAcceso);
