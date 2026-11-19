import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/rotacion_view.dart';
import 'package:gip/presentation/negocio/rotacion_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'datos_alertas.dart';
import 'rotacion_falsos.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  final huevo = productoAlertas('p4', 'Huevo AA');
  final velas = productoAlertas('p5', 'Velas');

  Future<void> abrir(
    WidgetTester tester,
    Size tamano, {
    Map<Producto, Rotacion>? rotacion,
    UsuarioActivo? usuario,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final coordinador = ConsultarRotacionFalso();
    when(() => coordinador.consultarRotacion(any(), any(), any(), any()))
        .thenAnswer((invocacion) async {
          if (invocacion.positionalArguments[3] == empleadoAlertas.usuario) {
            throw const ExcepcionSoloPropietario();
          }
          return rotacion ??
              {
                huevo: Rotacion.alta,
                coco: Rotacion.alta,
                platano: Rotacion.media,
                aceite: Rotacion.baja,
                velas: Rotacion.baja,
              };
        });
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => RotacionViewModel(
            coordinador,
            usuario ?? propietariaAlertas,
            reloj: () => DateTime(2026, 11, 11, 9),
          )..cargar(),
          child: const RotacionView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('móvil: muestra un grupo a la vez, empezando por Alta', (
    tester,
  ) async {
    await abrir(tester, movil);

    expect(tester.takeException(), isNull);
    expect(find.text('Rotación de productos'), findsWidgets);
    expect(find.text('Alta · 2'), findsOneWidget);
    expect(find.text('Media · 1'), findsOneWidget);
    expect(find.text('Baja · 2'), findsOneWidget);
    expect(find.text('Se vende mucho'), findsOneWidget);
    expect(find.text('Tercio de arriba'), findsOneWidget);
    expect(find.text('Huevo AA'), findsOneWidget);
    expect(find.text('Coco'), findsOneWidget);
    expect(find.text('Plátano'), findsNothing);
    expect(find.text('Velas'), findsNothing);
    expect(find.text(RotacionView.notaMovil), findsOneWidget);
  });

  testWidgets('móvil: tocar Baja cambia la lista sin desbordes', (
    tester,
  ) async {
    await abrir(tester, movil);

    await tester.tap(find.byKey(const Key('rotacion_grupo_2')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Se vende poco'), findsOneWidget);
    expect(find.text('Velas'), findsOneWidget);
    expect(find.text('Aceite 1 L'), findsOneWidget);
    expect(find.text('Huevo AA'), findsNothing);
  });

  testWidgets('móvil: los periodos y los grupos miden 44 px o más', (
    tester,
  ) async {
    await abrir(tester, movil);

    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSize(find.byKey(Key('rotacion_periodo_$i'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(find.byKey(Key('rotacion_grupo_$i'))).height,
        greaterThanOrEqualTo(44),
      );
    }
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('Este mes'), findsOneWidget);
    expect(find.text('Fechas'), findsOneWidget);
  });

  testWidgets('web: muestra los tres grupos lado a lado con su conteo', (
    tester,
  ) async {
    await abrir(tester, web);

    expect(tester.takeException(), isNull);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Baja'), findsOneWidget);
    expect(find.text('2 productos'), findsNWidgets(2));
    expect(find.text('1 producto'), findsOneWidget);
    for (final nombre in [
      'Huevo AA',
      'Coco',
      'Plátano',
      'Aceite 1 L',
      'Velas',
    ]) {
      expect(find.text(nombre), findsOneWidget);
    }
    expect(find.text('Últimos 30 días'), findsOneWidget);
    expect(find.text(RotacionView.notaWeb), findsOneWidget);
    // Sin selector de grupos: es solo del móvil.
    expect(find.byKey(const Key('rotacion_grupo_0')), findsNothing);
    final alta = tester.getTopLeft(
      find.byKey(const Key('rotacion_lista_alta')),
    );
    final media = tester.getTopLeft(
      find.byKey(const Key('rotacion_lista_media')),
    );
    final baja = tester.getTopLeft(
      find.byKey(const Key('rotacion_lista_baja')),
    );
    expect(alta.dx, lessThan(media.dx));
    expect(media.dx, lessThan(baja.dx));
    expect(alta.dy, media.dy);
  });

  testWidgets('web: Baja va en rojo, Media en gris y Alta en verde', (
    tester,
  ) async {
    await abrir(tester, web);

    TonoEstado tono(String texto) => tester
        .widget<PildoraEstado>(find.widgetWithText(PildoraEstado, texto))
        .tono;
    expect(tono('1 producto'), TonoEstado.neutro);
    expect(
      tester
          .widgetList<PildoraEstado>(find.byType(PildoraEstado))
          .map((p) => p.tono),
      [TonoEstado.bien, TonoEstado.neutro, TonoEstado.error],
    );
  });

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    testWidgets('$nombre: un grupo vacío lo dice', (tester) async {
      await abrir(tester, tamano, rotacion: {huevo: Rotacion.alta});
      if (tamano == movil) {
        await tester.tap(find.byKey(const Key('rotacion_grupo_1')));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('rotacion_vacio_media')), findsOneWidget);
    });

    testWidgets('$nombre: sin productos lo dice y no hay listas', (
      tester,
    ) async {
      await abrir(tester, tamano, rotacion: {});

      expect(find.byKey(const Key('rotacion_sin_productos')), findsOneWidget);
      expect(find.text('Todavía no hay productos registrados'), findsOneWidget);
      expect(find.byKey(const Key('rotacion_lista_alta')), findsNothing);
    });

    testWidgets('$nombre: el empleado ve que es solo del propietario', (
      tester,
    ) async {
      await abrir(tester, tamano, usuario: empleadoAlertas);

      expect(
        find.text('Esta consulta es solo para el propietario'),
        findsOneWidget,
      );
      expect(find.text('Huevo AA'), findsNothing);
      expect(find.byKey(const Key('rotacion_periodo_0')), findsNothing);
    });

    testWidgets('$nombre: elegir Este mes consulta de nuevo', (tester) async {
      await abrir(tester, tamano);

      await tester.tap(find.byKey(const Key('rotacion_periodo_1')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Huevo AA'), findsOneWidget);
    });
  }
}
