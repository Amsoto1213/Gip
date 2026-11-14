import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/main.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

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
  });

  Widget app() => GipApp(
    iniciarSesion: IniciarSesionCoordinator(
      ServicioAcceso(autenticacion, sesionLocal),
    ),
  );

  testWidgets('sin sesión guardada muestra el inicio de sesión', (
    tester,
  ) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('con sesión guardada entra directo', (tester) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Hola, Carmen'), findsOneWidget);
    expect(find.text('Granero El Porvenir'), findsOneWidget);
  });

  testWidgets('con la clave mala muestra el mensaje y se queda', (
    tester,
  ) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);
    when(() => autenticacion.iniciarSesion(any(), any()))
        .thenThrow(const ExcepcionCredencialesInvalidas());

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'carmen@gip.test');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('con datos correctos entra', (tester) async {
    when(() => autenticacion.haySesionGuardada()).thenReturn(false);
    when(() => autenticacion.iniciarSesion('carmen@gip.test', 'gip12345'))
        .thenAnswer((_) async => carmen);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'carmen@gip.test');
    await tester.enterText(find.byType(TextField).at(1), 'gip12345');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Carmen'), findsOneWidget);
  });
}
