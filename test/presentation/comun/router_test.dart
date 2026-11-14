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
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/main.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:mocktail/mocktail.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

class GestionarProductoFalso extends Mock
    implements GestionarProductoCoordinator {}

class BuscarProductoFalso extends Mock implements BuscarProductoCoordinator {}

class RegistrarEntradaFalso extends Mock
    implements RegistrarEntradaMercanciaCoordinator {}

class RegistrarVentaFalso extends Mock implements RegistrarVentaCoordinator {}

const secciones = ['Vender', 'Surtido', 'Fiados', 'Caja', 'Negocio'];

void main() {
  final UsuarioActivo carmen = (
    usuario: Administrador('2222', 'Carmen', '1000000001'),
    tienda: Tienda('1111', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar'),
  );

  /// Abre la app con sesión guardada en una pantalla de [ancho] x [alto].
  Future<void> abrir(WidgetTester tester, double ancho, double alto) async {
    tester.view.physicalSize = Size(ancho, alto);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final autenticacion = AutenticacionFalsa();
    final sesionLocal = SesionLocalFalsa();
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);

    await tester.pumpWidget(
      GipApp(
        iniciarSesion: IniciarSesionCoordinator(
          ServicioAcceso(autenticacion, sesionLocal),
        ),
        gestionarProducto: GestionarProductoFalso(),
        buscarProducto: BuscarProductoFalso(),
        registrarEntradaMercancia: RegistrarEntradaFalso(),
        registrarVenta: RegistrarVentaFalso(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder titulo(String texto) => find.descendant(
    of: find.byType(PantallaSeccion),
    matching: find.text(texto),
  );

  testWidgets('en pantalla angosta muestra las 5 secciones abajo', (
    tester,
  ) async {
    await abrir(tester, 390, 844);

    expect(find.byType(NavigationRail), findsNothing);
    final barra = find.byType(NavigationBar);
    expect(barra, findsOneWidget);
    for (final seccion in secciones) {
      expect(
        find.descendant(of: barra, matching: find.text(seccion)),
        findsOneWidget,
      );
    }
    expect(titulo('Vender'), findsOneWidget);
  });

  testWidgets('en pantalla ancha muestra las 5 secciones al lado', (
    tester,
  ) async {
    await abrir(tester, 1280, 800);

    expect(find.byType(NavigationBar), findsNothing);
    final barra = find.byType(NavigationRail);
    expect(barra, findsOneWidget);
    for (final seccion in secciones) {
      expect(
        find.descendant(of: barra, matching: find.text(seccion)),
        findsOneWidget,
      );
    }
    expect(tester.widget<NavigationRail>(barra).extended, isTrue);
    expect(find.text('Granero El Porvenir'), findsOneWidget);
  });

  testWidgets('en tableta la barra lateral va sin extender', (tester) async {
    await abrir(tester, 800, 1000);

    final barra = find.byType(NavigationRail);
    expect(barra, findsOneWidget);
    expect(tester.widget<NavigationRail>(barra).extended, isFalse);
  });

  for (final (ancho, alto) in [(390.0, 844.0), (1280.0, 800.0)]) {
    testWidgets('a $ancho px, tocar cada sección muestra su pantalla', (
      tester,
    ) async {
      await abrir(tester, ancho, alto);

      for (final seccion in secciones.reversed) {
        await tester.tap(find.text(seccion).last);
        await tester.pumpAndSettle();
        expect(titulo(seccion), findsOneWidget);
      }
    });
  }

  testWidgets('Surtido abre Producto nuevo y Volver regresa', (tester) async {
    await abrir(tester, 390, 844);

    await tester.tap(find.text('Surtido').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Producto nuevo'));
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
    await tester.tap(find.text('Buscar producto'));
    await tester.pumpAndSettle();
    expect(find.byType(BuscarProductoView), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(BuscarProductoView), findsNothing);
    expect(titulo('Surtido'), findsOneWidget);
  });
}
