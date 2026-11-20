import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/casilla_registro.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/conflictos_view.dart';
import 'package:gip/presentation/negocio/conflictos_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'conflictos_falsos.dart';
import 'datos_alertas.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);
  final fecha = DateTime.utc(2026, 11, 19, 15, 45);

  ConflictoSincronizacion duplicado() => ConflictoSincronizacion(
    'dup',
    TipoConflicto.posibleDuplicado,
    'Dos entradas iguales de huevos',
    ['m1', 'm2'],
    fecha,
    etiquetasRegistros: ['Entrada de las 10:42', 'Entrada de las 10:44'],
  );
  ConflictoSincronizacion stock() => ConflictoSincronizacion(
    'stk',
    TipoConflicto.stockNegativo,
    'Huevo AA quedó en -6',
    ['m3', 'm4'],
    fecha,
  );
  ConflictoSincronizacion abono() => ConflictoSincronizacion(
    'abn',
    TipoConflicto.abonoExcedeSaldo,
    'Los abonos de María suman de más',
    ['f1', 'a1', 'a2'],
    fecha,
    etiquetasRegistros: ['Fiado de María', 'Abono 8.000', 'Abono 8.000 bis'],
  );
  ConflictoSincronizacion codigo() => ConflictoSincronizacion(
    'cod',
    TipoConflicto.codigoRepetido,
    'Dos productos con el mismo código',
    ['p1', 'p2'],
    fecha,
    etiquetasRegistros: ['Galletas', 'Galletas de coco'],
  );
  ConflictoSincronizacion caja() => ConflictoSincronizacion(
    'cja',
    TipoConflicto.movimientoCajaCerrada,
    'Llegó un movimiento a una caja cerrada',
    ['caja1', 'mc1'],
    fecha,
  );

  late RevisarConflictosFalso coordinador;
  late List<ConflictoSincronizacion> pendientes;
  var rutaAbierta = '';

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(duplicado());
    registerFallbackValue(propietariaAlertas.usuario);
  });

  Future<void> abrir(
    WidgetTester tester,
    Size tamano,
    List<ConflictoSincronizacion> lista, {
    bool empleado = false,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    pendientes = [...lista];
    rutaAbierta = '';
    coordinador = RevisarConflictosFalso();
    when(() => coordinador.consultarConflictos(any(), any()))
        .thenAnswer((i) async {
          if (empleado) throw const ExcepcionSoloPropietario();
          return [...pendientes];
        });
    when(() => coordinador.resolver(any(), any(), any(), any()))
        .thenAnswer((i) async {
          final c = i.positionalArguments[1] as ConflictoSincronizacion;
          pendientes.removeWhere((p) => p.getId() == c.getId());
        });
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(
          path: '/inicio',
          builder: (_, _) => ChangeNotifierProvider(
            create: (_) => ConflictosViewModel(
              coordinador,
              (empleado ? empleadoAlertas : propietariaAlertas),
            )..cargar(),
            child: const ConflictosView(),
          ),
        ),
        GoRoute(
          path: rutaConteo,
          builder: (_, _) {
            rutaAbierta = rutaConteo;
            return const Scaffold(body: Text('Pantalla de conteo'));
          },
        ),
        GoRoute(
          path: rutaPrincipalNegocio,
          builder: (_, _) => const Scaffold(body: Text('Negocio')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: TemaGip.claro(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  bool deshabilitado(WidgetTester tester, String clave) =>
      tester.widget<BotonPrimario>(find.byKey(Key(clave))).onPressed == null;

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    group(nombre, () {
      testWidgets('muestra el encabezado, el tipo y la descripción', (
        tester,
      ) async {
        await abrir(tester, tamano, [duplicado()]);

        expect(tester.takeException(), isNull);
        expect(find.text('Revisar sincronización'), findsWidgets);
        expect(find.text(ConflictosView.textoContexto), findsOneWidget);
        expect(find.text('Posible registro repetido'), findsOneWidget);
        expect(find.text('Dos entradas iguales de huevos'), findsOneWidget);
        expect(find.textContaining('Detectado'), findsOneWidget);
        expect(find.text('Entrada de las 10:42'), findsOneWidget);
        expect(find.text('Entrada de las 10:44'), findsOneWidget);
      });

      testWidgets('una entrada repetida varias veces es una sola tarjeta con '
          'todas las entradas', (tester) async {
        ConflictoSincronizacion pareja(String id, String otra) =>
            ConflictoSincronizacion(
              id,
              TipoConflicto.posibleDuplicado,
              'Dos entradas iguales de huevos',
              ['e0', otra],
              fecha,
              etiquetasRegistros: ['Entrada original', 'Entrada $otra'],
            );
        await abrir(tester, tamano, [pareja('d1', 'e1'), pareja('d2', 'e2')]);

        expect(find.byType(CasillaRegistro), findsNWidgets(3));
        expect(find.byKey(const Key('conflicto_d1')), findsOneWidget);
        expect(find.byKey(const Key('conflicto_d2')), findsNothing);
        expect(find.textContaining('3 entradas iguales'), findsOneWidget);

        await tocar(tester, find.byKey(const Key('registro_e0')));
        await tocar(tester, find.byKey(const Key('conflicto_guardar_d1')));

        final enviados = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured;
        expect(enviados, [
          ['e1'],
          ['e2'],
        ]);
      });

      testWidgets('sin conflictos dice que no hay nada por revisar', (
        tester,
      ) async {
        await abrir(tester, tamano, []);

        expect(find.byKey(const Key('conflictos_vacio')), findsOneWidget);
        expect(find.text(ConflictosView.textoSinConflictos), findsOneWidget);
      });

      testWidgets('el empleado ve que es solo para el propietario', (
        tester,
      ) async {
        await abrir(tester, tamano, [duplicado()], empleado: true);

        expect(find.byKey(const Key('conflictos_error_carga')), findsOneWidget);
        expect(
          find.text(ConflictosViewModel.mensajeSoloPropietario),
          findsOneWidget,
        );
        expect(find.byType(CasillaRegistro), findsNothing);
      });

      testWidgets('duplicado: guardar espera a que se marque algo y manda los '
          'no marcados', (tester) async {
        await abrir(tester, tamano, [duplicado()]);

        expect(deshabilitado(tester, 'conflicto_guardar_dup'), isTrue);

        await tocar(tester, find.byKey(const Key('registro_m1')));
        expect(deshabilitado(tester, 'conflicto_guardar_dup'), isFalse);

        await tocar(tester, find.byKey(const Key('conflicto_guardar_dup')));

        final enviados = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured.single;
        expect(enviados, ['m2']);
        expect(find.text('Conflicto resuelto'), findsOneWidget);
        expect(find.byKey(const Key('conflicto_dup')), findsNothing);
      });

      testWidgets('duplicado: "Son registros distintos" resuelve sin elegir', (
        tester,
      ) async {
        await abrir(tester, tamano, [duplicado()]);

        await tocar(tester, find.byKey(const Key('conflicto_distintos_dup')));

        final enviados = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured.single;
        expect(enviados, isEmpty);
        expect(find.text('Conflicto resuelto'), findsOneWidget);
      });

      testWidgets('existencia negativa: no tiene casillas; Aceptar así '
          'resuelve', (tester) async {
        await abrir(tester, tamano, [stock()]);

        expect(find.text('Existencia negativa'), findsOneWidget);
        expect(find.byType(CasillaRegistro), findsNothing);

        await tocar(tester, find.byKey(const Key('conflicto_aceptar_stk')));

        verify(() => coordinador.resolver(any(), any(), const [], any()))
            .called(1);
        expect(find.text('Conflicto resuelto'), findsOneWidget);
      });

      testWidgets('existencia negativa: Ir al conteo abre el conteo y no '
          'resuelve', (tester) async {
        await abrir(tester, tamano, [stock()]);

        await tocar(tester, find.byKey(const Key('conflicto_conteo_stk')));

        expect(rutaAbierta, rutaConteo);
        verifyNever(() => coordinador.resolver(any(), any(), any(), any()));
      });

      testWidgets('abono: el fiado no se elige y se anulan los marcados', (
        tester,
      ) async {
        await abrir(tester, tamano, [abono()]);

        expect(find.text('Abono mayor que el saldo'), findsOneWidget);
        expect(find.byKey(const Key('registro_f1')), findsNothing);
        expect(deshabilitado(tester, 'conflicto_guardar_abn'), isTrue);

        await tocar(tester, find.byKey(const Key('registro_a2')));
        await tocar(tester, find.byKey(const Key('conflicto_guardar_abn')));

        final enviados = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured.single;
        expect(enviados, ['a2']);
      });

      testWidgets('código repetido: Quitar el código manda el producto '
          'marcado', (tester) async {
        await abrir(tester, tamano, [codigo()]);

        expect(find.text('Código repetido'), findsOneWidget);
        await tocar(tester, find.byKey(const Key('registro_p2')));
        await tocar(tester, find.byKey(const Key('conflicto_guardar_cod')));

        final enviados = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured.single;
        expect(enviados, ['p2']);
      });

      testWidgets('caja cerrada: Aceptar y recalcular resuelve', (
        tester,
      ) async {
        await abrir(tester, tamano, [caja()]);

        expect(find.text('Movimiento en caja cerrada'), findsOneWidget);
        await tocar(tester, find.byKey(const Key('conflicto_aceptar_cja')));

        verify(() => coordinador.resolver(any(), any(), const [], any()))
            .called(1);
      });

      testWidgets('si falla, muestra el mensaje y deja el conflicto', (
        tester,
      ) async {
        await abrir(tester, tamano, [caja()]);
        when(() => coordinador.resolver(any(), any(), any(), any()))
            .thenThrow(StateError('falla'));

        await tocar(tester, find.byKey(const Key('conflicto_aceptar_cja')));

        expect(find.byKey(const Key('conflictos_error')), findsOneWidget);
        expect(find.byKey(const Key('conflicto_cja')), findsOneWidget);
      });

      testWidgets('varios conflictos: cada uno con su tarjeta, sin desbordes', (
        tester,
      ) async {
        await abrir(tester, tamano, [
          duplicado(),
          stock(),
          abono(),
          codigo(),
          caja(),
        ]);

        for (final id in ['dup', 'stk', 'abn', 'cod', 'cja']) {
          await tester.scrollUntilVisible(
            find.byKey(Key('conflicto_$id')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('los botones y las casillas miden 44 px o más', (
        tester,
      ) async {
        await abrir(tester, tamano, [duplicado()]);

        for (final f in [
          find.byKey(const Key('conflicto_guardar_dup')),
          find.byKey(const Key('conflicto_distintos_dup')),
          find.byType(CasillaRegistro).first,
        ]) {
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          expect(tester.getSize(f).height, greaterThanOrEqualTo(44));
        }
      });
    });
  }
}
