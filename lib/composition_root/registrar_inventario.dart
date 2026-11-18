import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_barras.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_qr.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/service_agents/impresion_etiquetas_pdf.dart';
import 'package:gip/transversal/configuracion/configuracion_inventario.dart';

/// Coordinadores del módulo gestion_inventario y el [ServicioInventario], que
/// usa el módulo pagos (CUS-02).
typedef CoordinadoresInventario = ({
  GestionarProductoCoordinator gestionarProducto,
  BuscarProductoCoordinator buscarProducto,
  RegistrarEntradaMercanciaCoordinator registrarEntradaMercancia,
  RegistrarPerdidaCoordinator registrarPerdida,
  RegistrarConteoCoordinator registrarConteo,
  ConsultarExistenciasCoordinator consultarExistencias,
  ServicioInventario servicioInventario,
});

/// Arma el módulo de inventario con sus implementaciones concretas.
///
/// Los intérpretes van en orden: código de barras primero y QR de último,
/// porque QR reconoce cualquier otro texto (CUS-17).
CoordinadoresInventario registrarInventario(
  BaseLocalDrift base,
  UnidadTrabajoDrift unidadTrabajo,
) {
  final productos = ProductoRepositorioDrift(base);
  final servicioInventario = ServicioInventario(
    InventarioRepositorioDrift(base),
    MovimientoInventarioRepositorioDrift(base),
    ConfiguracionInventario.umbralRevisionConteo,
    unidadTrabajo,
    productos,
  );
  final servicioCatalogo = ServicioCatalogo(
    productos,
    [InterpreteCodigoBarras(productos), InterpreteCodigoQR(productos)],
    servicioInventario,
    ImpresionEtiquetasPdf(),
    unidadTrabajo,
  );
  return (
    gestionarProducto: GestionarProductoCoordinator(servicioCatalogo),
    buscarProducto: BuscarProductoCoordinator(servicioCatalogo),
    registrarEntradaMercancia: RegistrarEntradaMercanciaCoordinator(
      servicioInventario,
    ),
    registrarPerdida: RegistrarPerdidaCoordinator(servicioInventario),
    registrarConteo: RegistrarConteoCoordinator(servicioInventario),
    consultarExistencias: ConsultarExistenciasCoordinator(servicioInventario),
    servicioInventario: servicioInventario,
  );
}
