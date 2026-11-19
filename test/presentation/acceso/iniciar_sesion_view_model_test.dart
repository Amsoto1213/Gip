import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:mocktail/mocktail.dart';

class IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

/// Revisión de la sesión guardada: si el propietario desactivó al usuario
/// mientras estaba dentro, la app lo saca (CUS-15, DI-44).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final UsuarioActivo luis = (
    usuario: Empleado('u2', 'Luis Gómez', '1000000002'),
    tienda: tienda,
  );
  final UsuarioActivo ana = (
    usuario: Empleado('u3', 'Ana Torres', '1000000003'),
    tienda: tienda,
  );

  const mensajeInactivo =
      'Tu usuario está desactivado. Habla con el propietario de la tienda';

  late IniciarSesionFalso coordinador;
  late IniciarSesionViewModel sesion;

  setUpAll(() => registerFallbackValue(luis));

  setUp(() {
    coordinador = IniciarSesionFalso();
    sesion = IniciarSesionViewModel(coordinador);
    when(() => coordinador.cerrarSesion()).thenAnswer((_) async {});
  });

  When<Future<bool>> alRevisar() =>
      when(() => coordinador.revisarUsuarioActivo(any()));

  /// Deja a [usuario] dentro por sesión guardada, sin esperar la revisión.
  Future<void> entrarGuardado(UsuarioActivo usuario) async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => usuario);
    await sesion.verificarSesionGuardada();
  }

  group('revisarUsuarioActivo', () {
    test(
      'desactivado: lo saca y deja el aviso para el inicio de sesión',
      () async {
        // Al abrir, todavía estaba activo.
        alRevisar().thenAnswer((_) async => true);
        await entrarGuardado(luis);
        await pumpEventQueue();
        expect(sesion.usuarioActivo, luis);
        var avisos = 0;
        sesion.addListener(() => avisos++);

        // Después el propietario lo desactiva; la app lo vuelve a revisar.
        alRevisar().thenAnswer((_) async => false);
        await sesion.revisarUsuarioActivo();

        expect(sesion.usuarioActivo, isNull);
        expect(sesion.error, mensajeInactivo);
        expect(avisos, 1);
      },
    );

    test('sigue activo: se queda dentro y sin aviso', () async {
      alRevisar().thenAnswer((_) async => true);
      await entrarGuardado(luis);
      await pumpEventQueue();

      await sesion.revisarUsuarioActivo();

      expect(sesion.usuarioActivo, luis);
      expect(sesion.error, isNull);
    });

    test('si la revisión falla, no cambia nada', () async {
      alRevisar().thenThrow(StateError('sin red'));
      await entrarGuardado(luis);
      await pumpEventQueue();

      await sesion.revisarUsuarioActivo();

      expect(sesion.usuarioActivo, luis);
      expect(sesion.error, isNull);
    });

    test('sin usuario dentro no pregunta nada', () async {
      await sesion.revisarUsuarioActivo();

      verifyNever(() => coordinador.revisarUsuarioActivo(any()));
    });

    test('mientras revisa no lanza otra revisión', () async {
      final espera = Completer<bool>();
      alRevisar().thenAnswer((_) => espera.future);
      // Al abrir ya queda una revisión en curso (la de arranque).
      await entrarGuardado(luis);
      await pumpEventQueue();

      await sesion.revisarUsuarioActivo();
      await sesion.revisarUsuarioActivo();
      espera.complete(true);
      await pumpEventQueue();

      verify(() => coordinador.revisarUsuarioActivo(any())).called(1);
    });

    test(
      'si mientras tanto entró otra persona, la respuesta no le toca',
      () async {
        final espera = Completer<bool>();
        alRevisar().thenAnswer((_) => espera.future);
        await entrarGuardado(luis);
        await pumpEventQueue();

        // Luis sale y entra Ana mientras el servidor contesta lo de Luis.
        await sesion.cerrarSesion();
        when(() => coordinador.iniciarSesion(any(), any()))
            .thenAnswer((_) async => ana);
        await sesion.iniciarSesion('ana@gip.test', 'gip12345');
        espera.complete(false);
        await pumpEventQueue();

        expect(sesion.usuarioActivo, ana);
        expect(sesion.error, isNull);
      },
    );

    test(
      'si se descarta el view model antes de que conteste, no falla',
      () async {
        final espera = Completer<bool>();
        alRevisar().thenAnswer((_) => espera.future);
        await entrarGuardado(luis);
        await pumpEventQueue();

        // La revisión de arranque sigue pendiente cuando se descarta.
        sesion.dispose();
        espera.complete(false);

        // Si avisara a un view model descartado, saltaría un error sin
        // atender y la prueba fallaría.
        await pumpEventQueue();
      },
    );
  });

  group('al abrir la app con una sesión guardada', () {
    test('revisa en segundo plano, sin demorar la entrada', () async {
      final espera = Completer<bool>();
      alRevisar().thenAnswer((_) => espera.future);
      when(() => coordinador.sesionGuardada()).thenAnswer((_) async => luis);

      await sesion.verificarSesionGuardada();

      // Ya entró y la revisión sigue pendiente.
      expect(sesion.verificandoSesion, isFalse);
      expect(sesion.usuarioActivo, luis);
      espera.complete(true);
      await pumpEventQueue();
    });

    test('si está desactivado, termina fuera con el aviso', () async {
      alRevisar().thenAnswer((_) async => false);

      await entrarGuardado(luis);
      await pumpEventQueue();

      expect(sesion.usuarioActivo, isNull);
      expect(sesion.error, mensajeInactivo);
    });

    test('sin sesión guardada no revisa nada', () async {
      when(() => coordinador.sesionGuardada()).thenAnswer((_) async => null);

      await sesion.verificarSesionGuardada();
      await pumpEventQueue();

      verifyNever(() => coordinador.revisarUsuarioActivo(any()));
    });

    test(
      'con un inicio de sesión nuevo no revisa: el inicio ya lo comprobó',
      () async {
        when(() => coordinador.iniciarSesion(any(), any()))
            .thenAnswer((_) async => luis);

        await sesion.iniciarSesion('luis@gip.test', 'gip12345');
        await pumpEventQueue();

        verifyNever(() => coordinador.revisarUsuarioActivo(any()));
      },
    );
  });
}
