import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/datos_actualizados.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/aviso_conflictos_pendientes.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'conflictos_falsos.dart';
import 'datos_alertas.dart';

class _IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

void main() {
  final fecha = DateTime.utc(2026, 11, 20, 15);
  List<ConflictoSincronizacion> conflictos(int n) => [
    for (var i = 0; i < n; i++)
      ConflictoSincronizacion(
        'c$i',
        TipoConflicto.posibleDuplicado,
        'Dos entradas iguales',
        ['a$i', 'b$i'],
        fecha,
      ),
  ];

  late RevisarConflictosFalso coordinador;
  late IniciarSesionViewModel sesion;
  late DatosActualizados datos;
  late int pedidos;

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() {
    coordinador = RevisarConflictosFalso();
    datos = DatosActualizados();
    pedidos = 0;
  });

  /// Monta el aviso con los proveedores de la app. Con [conProveedores] falso
  /// no pone ninguno, como en una pantalla probada sola.
  Future<void> montar(
    WidgetTester tester, {
    UsuarioActivo? usuario,
    bool conProveedores = true,
    Size tamano = const Size(360, 640),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final iniciar = _IniciarSesionFalso();
    when(() => iniciar.sesionGuardada())
        .thenAnswer((_) async => usuario ?? propietariaAlertas);
    sesion = IniciarSesionViewModel(iniciar);
    await sesion.verificarSesionGuardada();
    Widget hijo = const Scaffold(
      body: SingleChildScrollView(child: AvisoConflictosPendientes()),
    );
    if (conProveedores) {
      hijo = MultiProvider(
        providers: [
          ChangeNotifierProvider<IniciarSesionViewModel>.value(value: sesion),
          Provider<RevisarConflictosCoordinator>.value(value: coordinador),
          ChangeNotifierProvider<DatosActualizados>.value(value: datos),
        ],
        child: hijo,
      );
    }
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => hijo),
        GoRoute(
          path: rutaConflictos,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: context.pop,
              child: const Text('Volver'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: TemaGip.claro(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  void devolver(int n) =>
      when(() => coordinador.consultarConflictos(any(), any()))
          .thenAnswer((_) async {
            pedidos++;
            return conflictos(n);
          });

  testWidgets('con conflictos pendientes dice cuántos y explica el stock', (
    tester,
  ) async {
    devolver(2);
    await montar(tester);

    expect(find.byKey(const Key('aviso_conflictos')), findsOneWidget);
    expect(
      find.textContaining('Hay 2 conflictos por revisar.'),
      findsOneWidget,
    );
    expect(
      find.textContaining(AvisoConflictosPendientes.detalle),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('con uno dice "1 conflicto" en singular', (tester) async {
    devolver(1);
    await montar(tester);

    expect(find.textContaining('Hay 1 conflicto por revisar.'), findsOneWidget);
  });

  testWidgets('sin conflictos no sale nada', (tester) async {
    devolver(0);
    await montar(tester);

    expect(find.byKey(const Key('aviso_conflictos')), findsNothing);
  });

  testWidgets('si no es el propietario no sale nada', (tester) async {
    when(() => coordinador.consultarConflictos(any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());
    await montar(tester, usuario: empleadoAlertas);

    expect(find.byKey(const Key('aviso_conflictos')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('si falla la consulta no sale nada ni se rompe', (tester) async {
    when(() => coordinador.consultarConflictos(any(), any()))
        .thenThrow(StateError('falla'));
    await montar(tester);

    expect(find.byKey(const Key('aviso_conflictos')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin los proveedores de la app no sale nada', (tester) async {
    await montar(tester, conProveedores: false);

    expect(find.byKey(const Key('aviso_conflictos')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cuando llegan datos de otros equipos vuelve a contar', (
    tester,
  ) async {
    devolver(1);
    await montar(tester);
    expect(find.textContaining('Hay 1 conflicto por revisar.'), findsOneWidget);

    devolver(3);
    datos.avisar();
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hay 3 conflictos por revisar.'),
      findsOneWidget,
    );
  });

  testWidgets('Revisar abre Revisar sincronización y al volver vuelve a '
      'contar', (tester) async {
    devolver(2);
    await montar(tester);
    final antes = pedidos;

    await tester.tap(find.byKey(const Key('aviso_conflictos_revisar')));
    await tester.pumpAndSettle();
    expect(find.text('Volver'), findsOneWidget);

    devolver(0);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    expect(pedidos, greaterThan(antes));
    expect(find.byKey(const Key('aviso_conflictos')), findsNothing);
  });

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets(
      'a ${tamano.width.toInt()} px no se desborda y el botón mide 44 px o '
      'más',
      (tester) async {
        devolver(2);
        await montar(tester, tamano: tamano);

        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSize(find.byKey(const Key('aviso_conflictos_revisar')))
              .height,
          greaterThanOrEqualTo(44),
        );
      },
    );
  }
}
