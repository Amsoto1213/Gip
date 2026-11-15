import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/negocio/disparador_alertas_diarias.dart';
import 'package:mocktail/mocktail.dart';

import 'alertas_falsos.dart';

class IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final UsuarioActivo carmen = (
    usuario: Administrador('u1', 'Carmen', '1000000001'),
    tienda: tienda,
  );
  final UsuarioActivo luis = (
    usuario: Empleado('u2', 'Luis', '1000000002'),
    tienda: tienda,
  );

  late IniciarSesionFalso coordinador;
  late IniciarSesionViewModel sesion;
  late GenerarAlertasFalso generar;
  var ahora = DateTime(2026, 11, 15, 6, 10);

  setUp(() {
    coordinador = IniciarSesionFalso();
    sesion = IniciarSesionViewModel(coordinador);
    generar = GenerarAlertasFalso();
    ahora = DateTime(2026, 11, 15, 6, 10);
    when(() => coordinador.cerrarSesion()).thenAnswer((_) async {});
  });

  DisparadorAlertasDiarias crear() =>
      DisparadorAlertasDiarias(sesion, generar, reloj: () => ahora);

  test('sin usuario activo no genera', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => null);
    crear();
    await sesion.verificarSesionGuardada();

    expect(generar.ejecuciones, isEmpty);
  });

  test(
    'con la sesión guardada genera una vez para la tienda y la fecha',
    () async {
      when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
      final disparador = crear();
      await sesion.verificarSesionGuardada();
      await disparador.ultimaEjecucion;

      expect(generar.ejecuciones, hasLength(1));
      expect(generar.ejecuciones.single.$1, tienda);
      expect(generar.ejecuciones.single.$2, ahora);
    },
  );

  test('al iniciar sesión también genera, aunque sea el empleado', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => null);
    when(() => coordinador.iniciarSesion(any(), any()))
        .thenAnswer((_) async => luis);
    crear();
    await sesion.verificarSesionGuardada();
    await sesion.iniciarSesion('luis@tienda.co', 'clave');

    expect(generar.ejecuciones, hasLength(1));
  });

  test('otros avisos del mismo día no lo repiten', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    crear();
    await sesion.verificarSesionGuardada();
    await sesion.verificarSesionGuardada();

    expect(generar.ejecuciones, hasLength(1));
  });

  test('si cambia el día vuelve a generar en el siguiente aviso', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    crear();
    await sesion.verificarSesionGuardada();
    ahora = DateTime(2026, 11, 16, 0, 5);
    await sesion.verificarSesionGuardada();

    expect(generar.ejecuciones.map((e) => e.$2.day), [15, 16]);
  });

  test('un fallo no llega a la pantalla', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    generar.error = StateError('falla del disco');
    final disparador = crear();
    await sesion.verificarSesionGuardada();

    await expectLater(disparador.ultimaEjecucion, completes);
    expect(sesion.usuarioActivo, carmen);
  });

  test('después de dispose ya no escucha la sesión', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    crear().dispose();
    await sesion.verificarSesionGuardada();

    expect(generar.ejecuciones, isEmpty);
  });
}
