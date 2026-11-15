import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

void main() {
  late IniciarSesionFalso coordinador;

  setUp(() => coordinador = IniciarSesionFalso());

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => IniciarSesionViewModel(coordinador),
        child: MaterialApp(
          theme: TemaGip.claro(),
          home: const IniciarSesionView(),
        ),
      ),
    );
  }

  testWidgets('móvil: panel arriba, formulario y avisos', (tester) async {
    await abrir(tester, const Size(390, 844));

    expect(find.text('GIP'), findsOneWidget);
    expect(find.text('Gestor de Inventario Predictivo'), findsOneWidget);
    expect(find.text('Bienvenido de nuevo'), findsNothing);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Con el correo de su tienda.'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(
      find.text('Después de la primera vez, abre sin internet'),
      findsOneWidget,
    );
    expect(find.textContaining('¿Olvidó la contraseña?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web: dos mitades con el panel y la tarjeta', (tester) async {
    await abrir(tester, const Size(1440, 900));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(
      find.text('Entre con el correo y la contraseña de su tienda.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('la app abre aunque no haya internet'),
      findsOneWidget,
    );
    expect(find.textContaining('¿Olvidó la contraseña?'), findsOneWidget);
    // El formulario queda en la mitad derecha.
    expect(tester.getCenter(find.text('Iniciar sesión')).dx, greaterThan(720));
    expect(tester.takeException(), isNull);
  });

  testWidgets('en un teléfono de 5" no se desborda', (tester) async {
    await abrir(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Entrar'));
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Entrar envía el correo y la contraseña', (tester) async {
    when(() => coordinador.iniciarSesion(any(), any())).thenAnswer(
      (_) async => (
        usuario: Administrador('1', 'Carmen Ruiz', '1'),
        tienda: Tienda('2', 'T001', 'Granero El Porvenir', 'Arjona, Bolívar'),
      ),
    );
    await abrir(tester, const Size(390, 844));

    await tester.enterText(
      find.byKey(const Key('acceso_correo')),
      'carmen@gip.test',
    );
    await tester.enterText(find.byKey(const Key('acceso_clave')), 'gip12345');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    verify(() => coordinador.iniciarSesion('carmen@gip.test', 'gip12345'))
        .called(1);
  });

  testWidgets('muestra el error y deja ver la contraseña', (tester) async {
    when(() => coordinador.iniciarSesion(any(), any()))
        .thenThrow(ExcepcionCredencialesInvalidas());
    await abrir(tester, const Size(390, 844));

    final clave = find.byKey(const Key('acceso_clave'));
    expect(tester.widget<TextField>(clave).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(tester.widget<TextField>(clave).obscureText, isFalse);

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text(ExcepcionCredencialesInvalidas().mensaje), findsOneWidget);
  });
}
