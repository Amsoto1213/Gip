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
import 'package:gip/data/service_agents/impresion_etiquetas_pendiente.dart';
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
/// Piezas de relleno (DI-15), que ningún flujo actual llama: lista vacía de
/// intérpretes (CUS-17) e impresión de etiquetas (iteración 4).
CoordinadoresInventario registrarInventario(
  BaseLocalDrift base,
  UnidadTrabajoDrift unidadTrabajo,
) {
  final servicioInventario = ServicioInventario(
    InventarioRepositorioDrift(base),
    MovimientoInventarioRepositorioDrift(base),
    ConfiguracionInventario.umbralRevisionConteo,
    unidadTrabajo,
  );
  final servicioCatalogo = ServicioCatalogo(
    ProductoRepositorioDrift(base),
    const [],
    servicioInventario,
    const ImpresionEtiquetasPendiente(),
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
