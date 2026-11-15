import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_venta_perdida_coordinator.dart';
import 'package:mocktail/mocktail.dart';

/// Anota cada ejecución de CUS-24 sin calcular nada.
class GenerarAlertasFalso extends Fake
    implements GenerarAlertasDiariasCoordinator {
  final List<(Tienda, DateTime)> ejecuciones = [];
  Object? error;

  @override
  Future<void> ejecutar(Tienda tienda, DateTime fecha) async {
    ejecuciones.add((tienda, fecha));
    if (error case final e?) throw e;
  }
}

/// CUS-13 sin guardar nada.
class RegistrarVentaPerdidaFalso extends Fake
    implements RegistrarVentaPerdidaCoordinator {}

class ConsultarAlertasFalso extends Mock
    implements ConsultarAlertasCoordinator {}

/// Consulta que no encuentra alertas ni ventas perdidas.
class ConsultarAlertasVacio extends Fake
    implements ConsultarAlertasCoordinator {
  @override
  Future<List<AlertaReabastecimiento>> consultarAlertas(
    Tienda tienda,
    DateTime fecha,
    Usuario usuario,
  ) async => const [];

  @override
  Future<List<VentaPerdida>> consultarVentasPerdidas(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    Usuario usuario,
  ) async => const [];
}
