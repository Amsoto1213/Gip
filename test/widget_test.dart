import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/main.dart';
import 'package:gip/presentation/comun/barra_inferior.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import 'presentation/negocio/alertas_falsos.dart';
import 'presentation/negocio/margen_falsos.dart';
import 'presentation/negocio/reporte_falsos.dart';
import 'presentation/surtido/existencias_falsos.dart';
import 'presentation/caja/caja_falsos.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

class GestionarProductoFalso extends Mock
    implements GestionarProductoCoordinator {}

class BuscarProductoFalso extends Mock implements BuscarProductoCoordinator {}

class RegistrarEntradaFalso extends Mock
    implements RegistrarEntradaMercanciaCoordinator {}

class RegistrarPerdidaFalso extends Mock
    implements RegistrarPerdidaCoordinator {}

class RegistrarConteoFalso extends Mock implements RegistrarConteoCoordinator {}

class RegistrarVentaFalso extends Mock implements RegistrarVentaCoordinator {}

class RegistrarFiadoFalso extends Mock implements RegistrarFiadoCoordinator {}

class RegistrarAbonoFalso extends Mock implements RegistrarAbonoCoordinator {}

class ConsultarClienteFalso extends Mock
    implements ConsultarClienteCoordinator {}

const secciones = ['Vender', 'Surtido', 'Fiados', 'Caja', 'Negocio'];

void main() {
  final UsuarioActivo carmen = (
    usuario: Administrador('2222', 'Carmen', '1000000001'),
    tienda: Tienda('1111', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar'),
  );

  late AutenticacionFalsa autenticacion;
  late SesionLocalFalsa sesionLocal;

  setUpAll(() => registerFallbackValue(carmen));

  setUp(() {
    autenticacion = AutenticacionFalsa();
    sesionLocal = SesionLocalFalsa();
    when(() => sesionLocal.guardar(any())).thenAnswer((_) async {});
    when(() => sesionLocal.borrar()).thenAnswer((_) async {});
    when(() => autenticacion.cerrarSesion()).thenAnswer((_) async {});
  });

  Widget app() => GipApp(
    iniciarSesion: IniciarSesionCoordinator(
      ServicioAcceso(autenticacion, sesionLocal),
    ),
    gestionarProducto: GestionarProductoFalso(),
    buscarProducto: BuscarProductoFalso(),
    registrarEntradaMercancia: RegistrarEntradaFalso(),
    registrarPerdida: RegistrarPerdidaFalso(),
    registrarConteo: RegistrarConteoFalso(),
    consultarExistencias: ConsultarExistenciasFalso(),
    registrarVenta: RegistrarVentaFalso(),
    registrarFiado: RegistrarFiadoFalso(),
    registrarAbono: RegistrarAbonoFalso(),
    consultarCliente: ConsultarClienteFalso(),
    generarAlertas: GenerarAlertasFalso(),
    consultarAlertas: ConsultarAlertasFalso(),
    registrarVentaPerdida: RegistrarVentaPerdidaFalso(),
    consultarMargen: ConsultarMargenFalso(),
    generarReporteDiario: GenerarReporteDiarioFalso(),
    registrarMovimientoCaja: RegistrarMovimientoCajaFalso(),
    registrarCierreCaja: RegistrarCierreCajaFalso(),
  );

  /// Abre la app en una pantalla de teléfono (barra de pestañas abajo).
  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
  }

  Finder barra() => find.byType(BarraInferior);

  /// Las 5 pestañas de la navegación principal están a la vista.
  void expectCincoPestanas() {
    expect(barra(), findsOneWidget);
    for (final seccion in secciones) {
      expect(
        find.descendant(of: barra(), matching: find.text(seccion)),
        findsOneWidget,
      );
    }
  }

  Finder titulo(String texto) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is PantallaSeccion || w is EncabezadoPantalla,
    ),
    matching: find.text(texto),
  );

  /// Abre la app con la sesión guardada y va a la pestaña Negocio.
  Future<void> entrarANegocio(WidgetTester tester) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);
    await abrir(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: barra(), matching: find.text('Negocio')),
    );
    await tester.pumpAndSettle();
    expect(titulo('Negocio'), findsOneWidget);
  }

  testWidgets('sin sesión guardada muestra el inicio de sesión', (
    tester,
  ) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);

    await abrir(tester);
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(barra(), findsNothing);
  });

  testWidgets('con sesión guardada entra directo a las 5 pestañas', (
    tester,
  ) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);

    await abrir(tester);
    await tester.pumpAndSettle();

    expectCincoPestanas();
    expect(titulo('Vender'), findsOneWidget);
    expect(find.text('Hola, Carmen'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('con la clave mala muestra el mensaje y se queda', (
    tester,
  ) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);
    when(() => autenticacion.iniciarSesion(any(), any()))
        .thenThrow(const ExcepcionCredencialesInvalidas());

    await abrir(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'carmen@gip.test');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('con datos correctos entra a Vender', (tester) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);
    when(() => autenticacion.iniciarSesion('carmen@gip.test', 'gip12345'))
        .thenAnswer((_) async => carmen);

    await abrir(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'carmen@gip.test');
    await tester.enterText(find.byType(TextField).at(1), 'gip12345');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expectCincoPestanas();
    expect(titulo('Vender'), findsOneWidget);
    expect(find.text('Hola, Carmen'), findsOneWidget);
  });

  testWidgets('Cerrar sesión en Negocio vuelve al inicio de sesión', (
    tester,
  ) async {
    await entrarANegocio(tester);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => sesionLocal.borrar()).called(1);
    verify(() => autenticacion.cerrarSesion()).called(1);
    expect(find.text('Entrar'), findsOneWidget);
    expect(barra(), findsNothing);
  });

  testWidgets(
    'sin internet, Cerrar sesión igual borra la sesión local y sale',
    (tester) async {
      when(() => autenticacion.cerrarSesion())
          .thenThrow(const ExcepcionSinConexion());
      await entrarANegocio(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(() => sesionLocal.borrar()).called(1);
      expect(find.text('Entrar'), findsOneWidget);
      expect(barra(), findsNothing);
    },
  );
}
