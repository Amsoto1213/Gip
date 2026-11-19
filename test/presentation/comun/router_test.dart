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
import 'package:gip/presentation/caja/cierre_caja_view.dart';
import 'package:gip/presentation/comun/marco_navegacion.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/negocio/alertas_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/perdida_view.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:mocktail/mocktail.dart';

import '../negocio/alertas_falsos.dart';
import '../negocio/margen_falsos.dart';
import '../negocio/reporte_falsos.dart';
import '../surtido/existencias_falsos.dart';
import '../caja/caja_falsos.dart';

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
    usuario: Administrador('2222', 'Carmen Ruiz', '1000000001'),
    tienda: Tienda('1111', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar'),
  );

  setUpAll(() => registerFallbackValue(carmen.tienda));

  /// Abre la app con sesión guardada en una pantalla de [ancho] x [alto].
  Future<void> abrir(WidgetTester tester, double ancho, double alto) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final autenticacion = AutenticacionFalsa();
    final sesionLocal = SesionLocalFalsa();
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);

    final clientes = ConsultarClienteFalso();
    when(() => clientes.buscarClientes(any(), any()))
        .thenAnswer((_) async => []);
    await tester.pumpWidget(
      GipApp(
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
        consultarCliente: clientes,
        generarAlertas: GenerarAlertasFalso(),
        consultarAlertas: ConsultarAlertasVacio(),
        registrarVentaPerdida: RegistrarVentaPerdidaFalso(),
        consultarMargen: ConsultarMargenFalso(),
        generarReporteDiario: GenerarReporteDiarioFalso(),
        registrarMovimientoCaja: RegistrarMovimientoCajaFalso(),
        registrarCierreCaja: RegistrarCierreCajaFalso(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder titulo(String texto) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is PantallaSeccion || w is EncabezadoPantalla,
    ),
    matching: find.text(texto),
  );

  testWidgets('en pantalla angosta muestra las 5 secciones abajo', (
    tester,
  ) async {
    await abrir(tester, 390, 844);

    expect(find.byType(MenuLateral), findsNothing);
    final barra = find.byType(BarraInferior);
    expect(barra, findsOneWidget);
    for (final seccion in secciones) {
      expect(
        find.descendant(of: barra, matching: find.text(seccion)),
        findsOneWidget,
      );
    }
    expect(tester.getSize(barra).height, BarraInferior.alto);
    // La sección activa lleva la píldora.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('barra_inferior_activa')),
          matching: find.byType(InkWell),
        ),
        matching: find.text('Vender'),
      ),
      findsOneWidget,
    );
    expect(titulo('Vender'), findsOneWidget);
  });

  testWidgets('en pantalla ancha, menú lateral con la tienda y el usuario', (
    tester,
  ) async {
    await abrir(tester, 1280, 800);

    expect(find.byType(BarraInferior), findsNothing);
    final menu = find.byType(MenuLateral);
    expect(menu, findsOneWidget);
    for (final seccion in secciones) {
      expect(
        find.descendant(of: menu, matching: find.text(seccion)),
        findsOneWidget,
      );
    }
    expect(find.text('Granero El Porvenir'), findsOneWidget);
    expect(find.text('Arjona, Bolívar'), findsOneWidget);
    expect(find.text('Carmen Ruiz'), findsOneWidget);
    expect(find.text('CR'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    // Vender no tiene subsecciones.
    expect(find.text('Entrada de mercancía'), findsNothing);
  });

  testWidgets('en tableta se usa la barra inferior', (tester) async {
    await abrir(tester, 800, 1000);

    expect(find.byType(BarraInferior), findsOneWidget);
    expect(find.byType(MenuLateral), findsNothing);
  });

  testWidgets('el menú muestra las subsecciones de Surtido y las abre', (
    tester,
  ) async {
    await abrir(tester, 1280, 800);

    await tester.tap(find.text('Surtido').first);
    await tester.pumpAndSettle();
    expect(find.text('Entrada de mercancía'), findsOneWidget);
    expect(find.text('Pérdida o devolución'), findsOneWidget);

    await tester.tap(find.text('Pérdida o devolución'));
    await tester.pumpAndSettle();
    // Pérdida abre sola la búsqueda del producto; al volver queda Pérdida
    // con su subsección marcada.
    expect(find.byType(BuscarProductoView), findsOneWidget);
    await tester.tap(find.byTooltip('Volver a Surtido'));
    await tester.pumpAndSettle();
    expect(find.byType(PerdidaView), findsOneWidget);
    final subseccion = tester.getSemantics(
      find.descendant(
        of: find.byType(MenuLateral),
        matching: find.text('Pérdida o devolución'),
      ),
    );
    expect(subseccion, isSemantics(isSelected: true));
  });

  testWidgets('el menú abre Alertas de surtido desde Negocio', (tester) async {
    await abrir(tester, 1280, 800);

    await tester.tap(find.text('Negocio').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MenuLateral),
        matching: find.text('Alertas de surtido'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertasView), findsOneWidget);
    expect(find.text('No hay productos por agotarse'), findsOneWidget);
  });

  test('el rol se muestra como Administrador o Empleado', () {
    expect(
      MarcoNavegacion.nombreRol(Administrador('1', 'Carmen', '1')),
      'Administrador',
    );
    expect(MarcoNavegacion.nombreRol(Empleado('2', 'Luis', '2')), 'Empleado');
  });

  for (final (ancho, alto) in [(390.0, 844.0), (1280.0, 800.0)]) {
    testWidgets('a $ancho px, tocar cada sección muestra su pantalla', (
      tester,
    ) async {
      await abrir(tester, ancho, alto);

      for (final seccion in secciones.reversed) {
        await tester.tap(find.text(seccion).last);
        await tester.pumpAndSettle();
        // En la web la caja se titula "Caja de hoy" (mockup `wCaja`).
        final esCajaWeb = seccion == 'Caja' && ancho >= 1024;
        expect(titulo(esCajaWeb ? 'Caja de hoy' : seccion), findsOneWidget);
      }
    });
  }

  testWidgets('el menú muestra las subsecciones de Caja y abre el cierre', (
    tester,
  ) async {
    await abrir(tester, 1280, 800);

    await tester.tap(find.text('Caja').first);
    await tester.pumpAndSettle();
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Cierre de caja'), findsOneWidget);

    await tester.tap(find.text('Cierre de caja'));
    await tester.pumpAndSettle();
    expect(find.byType(CierreCajaView), findsOneWidget);

    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();
    expect(find.byType(CierreCajaView), findsNothing);
  });

  testWidgets('Surtido abre Producto nuevo y Volver regresa', (tester) async {
    await abrir(tester, 390, 844);

    await tester.tap(find.text('Surtido').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Producto nuevo'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductoView), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductoView), findsNothing);
    expect(titulo('Surtido'), findsOneWidget);
  });

  testWidgets('Surtido abre Buscar producto y Volver regresa', (tester) async {
    await abrir(tester, 390, 844);

    await tester.tap(find.text('Surtido').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar en el surtido…'));
    await tester.pumpAndSettle();
    expect(find.byType(BuscarProductoView), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(BuscarProductoView), findsNothing);
    expect(titulo('Surtido'), findsOneWidget);
  });
}
