import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/disparador_sincronizacion.dart';
import 'package:mocktail/mocktail.dart';

class _IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

/// CUS-23: cuándo se dispara la sincronización (DI-47).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'Otra', 'Turbaco');
  final UsuarioActivo carmen = (
    usuario: Administrador('u1', 'Carmen', '1000000001'),
    tienda: tienda,
  );
  final UsuarioActivo deOtra = (
    usuario: Administrador('u9', 'Otra', '1000000009'),
    tienda: otraTienda,
  );

  late _IniciarSesionFalso coordinador;
  late IniciarSesionViewModel sesion;
  late StreamController<List<ConnectivityResult>> conexion;
  late List<Tienda> sincronizadas;
  var ahora = DateTime(2026, 11, 19, 10);
  Future<void> Function(Tienda) accion = (_) async {};

  setUp(() {
    coordinador = _IniciarSesionFalso();
    sesion = IniciarSesionViewModel(coordinador);
    conexion = StreamController<List<ConnectivityResult>>.broadcast();
    sincronizadas = [];
    ahora = DateTime(2026, 11, 19, 10);
    accion = (t) async => sincronizadas.add(t);
    when(() => coordinador.cerrarSesion()).thenAnswer((_) async {});
  });
  tearDown(() => conexion.close());

  DisparadorSincronizacion crear({
    Duration intervalo = const Duration(minutes: 5),
    Duration separacion = const Duration(seconds: 20),
  }) => DisparadorSincronizacion(
    sesion,
    (t) => accion(t),
    conexion: conexion.stream,
    intervalo: intervalo,
    separacion: separacion,
    reloj: () => ahora,
  );

  Future<void> entrar(UsuarioActivo u) async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => u);
    await sesion.verificarSesionGuardada();
  }

  test('sin usuario activo no sincroniza nada', () async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => null);
    final d = crear();
    await sesion.verificarSesionGuardada();
    conexion.add([ConnectivityResult.wifi]);
    await pumpEventQueue();
    d.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(sincronizadas, isEmpty);
    d.dispose();
  });

  test('al tener usuario activo sincroniza su tienda', () async {
    final d = crear();
    await entrar(carmen);
    await d.ultimaEjecucion;

    expect(sincronizadas, [tienda]);
    d.dispose();
  });

  test(
    'si ya había usuario activo al crearlo, sincroniza al arrancar',
    () async {
      await entrar(carmen);

      final d = crear();
      await d.ultimaEjecucion;

      expect(sincronizadas, [tienda]);
      d.dispose();
    },
  );

  test('un cambio en la sesión de la misma tienda no la repite', () async {
    final d = crear();
    await entrar(carmen);
    await d.ultimaEjecucion;

    await entrar(carmen);

    expect(sincronizadas, hasLength(1));
    d.dispose();
  });

  test('al entrar otra tienda sincroniza la nueva', () async {
    final d = crear();
    await entrar(carmen);
    await d.ultimaEjecucion;

    await entrar(deOtra);
    await d.ultimaEjecucion;

    expect(sincronizadas, [tienda, otraTienda]);
    d.dispose();
  });

  test(
    'al recuperar la conexión sincroniza aunque haya sido hace poco',
    () async {
      final d = crear();
      await entrar(carmen);
      await d.ultimaEjecucion;

      conexion.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      await d.ultimaEjecucion;

      expect(sincronizadas, hasLength(2));
      d.dispose();
    },
  );

  test('perder la conexión no sincroniza', () async {
    final d = crear();
    await entrar(carmen);
    await d.ultimaEjecucion;

    conexion.add([ConnectivityResult.none]);
    await pumpEventQueue();

    expect(sincronizadas, hasLength(1));
    d.dispose();
  });

  test(
    'al volver del segundo plano sincroniza, pero no dos veces seguidas',
    () async {
      final d = crear();
      await entrar(carmen);
      await d.ultimaEjecucion;

      ahora = ahora.add(const Duration(seconds: 5));
      d.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(sincronizadas, hasLength(1), reason: 'hace menos de 20 s');

      ahora = ahora.add(const Duration(seconds: 30));
      d.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await d.ultimaEjecucion;
      expect(sincronizadas, hasLength(2));

      d.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(sincronizadas, hasLength(2));
      d.dispose();
    },
  );

  testWidgets('cada intervalo sincroniza mientras haya usuario activo', (
    tester,
  ) async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    final d = crear(separacion: const Duration(seconds: 1));
    await sesion.verificarSesionGuardada();
    await tester.pump();
    expect(sincronizadas, hasLength(1));

    ahora = ahora.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(sincronizadas, hasLength(2));

    ahora = ahora.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(sincronizadas, hasLength(3));
    d.dispose();
  });

  testWidgets('al cerrar sesión deja de sincronizar', (tester) async {
    when(() => coordinador.sesionGuardada()).thenAnswer((_) async => carmen);
    final d = crear(separacion: const Duration(seconds: 1));
    await sesion.verificarSesionGuardada();
    await tester.pump();
    expect(sincronizadas, hasLength(1));

    await sesion.cerrarSesion();
    await tester.pump();
    ahora = ahora.add(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    d.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(sincronizadas, hasLength(1));
    d.dispose();
  });

  test('un fallo de la sincronización no tumba nada', () async {
    accion = (_) async => throw StateError('sin red');
    final d = crear();
    await entrar(carmen);
    await d.ultimaEjecucion;

    expect(sesion.usuarioActivo, isNotNull);
    d.dispose();
  });
}
