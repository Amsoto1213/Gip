import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/business/workflow/pagos/anular_venta_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class RegistrarMovimientoCajaFalso extends Mock
    implements RegistrarMovimientoCajaCoordinator {}

class RegistrarCierreCajaFalso extends Mock
    implements RegistrarCierreCajaCoordinator {}

class AnularVentaFalso extends Mock implements AnularVentaCoordinator {}
