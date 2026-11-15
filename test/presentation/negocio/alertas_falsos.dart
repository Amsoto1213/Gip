import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
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

class ConsultarAlertasFalso extends Mock
    implements ConsultarAlertasCoordinator {}
