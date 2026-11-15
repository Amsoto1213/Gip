import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/reporte_diario_view.dart';
import 'package:gip/presentation/negocio/reporte_diario_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'datos_alertas.dart';
import 'reporte_falsos.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  ReporteDiario reporte({
    String retiros = '0',
    bool incompleto = false,
    bool parcial = false,
    String ventas = '412300',
  }) => ReporteDiario(
    DateTime(2026, 11, 11),
    d(ventas),
    d('46000'),
    d('100300'),
    d('20500'),
    d('10000'),
    d('285400'),
    d('18000'),
    d('78800'),
    d(retiros),
    incompleto,
    parcial,
  );

  Future<GenerarReporteDiarioFalso> abrir(
    WidgetTester tester,
    Size tamano, {
    ReporteDiario? datos,
    UsuarioActivo? usuario,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final coordinador = GenerarReporteDiarioFalso();
    when(() => coordinador.generarReporte(any(), any(), any()))
        .thenAnswer((invocacion) async {
          if (invocacion.positionalArguments[2] == empleadoAlertas.usuario) {
            throw const ExcepcionSoloPropietario();
          }
          return datos ?? reporte();
        });
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => ReporteDiarioViewModel(
            coordinador,
            usuario ?? propietariaAlertas,
            reloj: () => DateTime(2026, 11, 11, 9),
          )..cargar(),
          child: const ReporteDiarioView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return coordinador;
  }

  /// La lista construye solo lo visible: baja hasta el texto antes de leerlo.
  Future<String> texto(WidgetTester tester, String clave) async {
    final buscado = find.byKey(Key(clave));
    if (buscado.evaluate().isEmpty) {
      await tester.scrollUntilVisible(buscado, 200);
    }
    return tester.widget<Text>(buscado).data!;
  }

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    testWidgets('$nombre: muestra las cifras del día sin desbordes', (
      tester,
    ) async {
      await abrir(tester, tamano);

      expect(tester.takeException(), isNull);
      expect(find.text('Reporte del día'), findsWidgets);
      expect(find.text('Hoy, mié. 11 nov.'), findsOneWidget);
      expect(await texto(tester, 'reporte_ventas'), '\$ 412.300');
      expect(await texto(tester, 'reporte_gastos'), '\$ 18.000');
      expect(await texto(tester, 'reporte_utilidad'), '\$ 78.800');
      expect(await texto(tester, 'reporte_ventas_nequi'), '\$ 100.300');
      expect(await texto(tester, 'reporte_abonos_nequi'), '\$ 10.000');
      expect(await texto(tester, 'reporte_nequi'), '\$ 110.300');
      expect(await texto(tester, 'reporte_entradas'), '\$ 285.400');
      expect(await texto(tester, 'reporte_fiado'), '\$ 46.000');
      expect(await texto(tester, 'reporte_abonos'), '\$ 20.500');
      expect(find.byType(TarjetaAviso), findsNothing);
      expect(find.byType(NotaInfo), findsNothing);
    });

    testWidgets('$nombre: los retiros personales salen aparte', (tester) async {
      await abrir(tester, tamano, datos: reporte(retiros: '40000'));

      expect(find.byKey(const Key('reporte_retiros')), findsOneWidget);
      expect(
        find.textContaining('Sacó para la casa: \$ 40.000.'),
        findsOneWidget,
      );
      // No se mezclan con la ganancia ni con los gastos.
      expect(await texto(tester, 'reporte_utilidad'), '\$ 78.800');
      expect(await texto(tester, 'reporte_gastos'), '\$ 18.000');
    });

    testWidgets('$nombre: incompleto avisa en rojo', (tester) async {
      await abrir(tester, tamano, datos: reporte(incompleto: true));

      expect(find.byKey(const Key('reporte_aviso_incompleto')), findsOneWidget);
      expect(find.byType(TarjetaAviso), findsOneWidget);
      expect(find.text('incompleta'), findsOneWidget);
      final rojo = Theme.of(
        tester.element(find.byKey(const Key('reporte_utilidad'))),
      ).colorScheme.error;
      expect(rojo, isNotNull);
      expect(find.byType(NotaInfo), findsNothing);
    });

    testWidgets('$nombre: parcial es una nota informativa, no un error', (
      tester,
    ) async {
      await abrir(tester, tamano, datos: reporte(parcial: true));

      expect(find.byKey(const Key('reporte_aviso_parcial')), findsOneWidget);
      expect(find.byType(NotaInfo), findsOneWidget);
      expect(find.text(ReporteDiarioView.textoParcial), findsOneWidget);
      expect(find.byType(TarjetaAviso), findsNothing);
    });

    testWidgets('$nombre: incompleto y parcial se muestran cada uno en su '
        'tono', (tester) async {
      await abrir(
        tester,
        tamano,
        datos: reporte(incompleto: true, parcial: true),
      );

      expect(find.byType(TarjetaAviso), findsOneWidget);
      expect(find.byType(NotaInfo), findsOneWidget);
    });

    testWidgets('$nombre: un día sin datos lo dice', (tester) async {
      await abrir(
        tester,
        tamano,
        datos: ReporteDiario(
          DateTime(2026, 11, 11),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          d('0'),
          false,
          false,
        ),
      );

      expect(find.byKey(const Key('reporte_sin_movimiento')), findsOneWidget);
      expect(await texto(tester, 'reporte_utilidad'), '\$ 0');
    });

    testWidgets('$nombre: el empleado ve que es solo para el propietario', (
      tester,
    ) async {
      await abrir(tester, tamano, usuario: empleadoAlertas);

      expect(find.byKey(const Key('reporte_error')), findsOneWidget);
      expect(
        find.text(ReporteDiarioViewModel.mensajeSoloPropietario),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reporte_ventas')), findsNothing);
    });

    testWidgets('$nombre: cambiar de día pide otro reporte y deja volver', (
      tester,
    ) async {
      final coordinador = await abrir(tester, tamano);
      // Hoy: no se puede avanzar.
      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: find.byKey(const Key('reporte_siguiente')),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('reporte_anterior')));
      await tester.pumpAndSettle();

      expect(find.text('mar. 10 nov.'), findsOneWidget);
      final fechas = verify(
        () => coordinador.generarReporte(any(), captureAny(), any()),
      ).captured.cast<DateTime>();
      expect(fechas.last, DateTime(2026, 11, 10));

      await tester.tap(find.byKey(const Key('reporte_siguiente')));
      await tester.pumpAndSettle();
      expect(find.text('Hoy, mié. 11 nov.'), findsOneWidget);
    });

    testWidgets('$nombre: los botones de fecha miden 44 px o más', (
      tester,
    ) async {
      await abrir(tester, tamano);

      for (final clave in [
        'reporte_anterior',
        'reporte_fecha',
        'reporte_siguiente',
      ]) {
        final tam = tester.getSize(find.byKey(Key(clave)));
        expect(tam.height, greaterThanOrEqualTo(44), reason: clave);
        expect(tam.width, greaterThanOrEqualTo(44), reason: clave);
      }
    });
  }

  testWidgets('la etiqueta de fecha lleva Hoy solo en el día de hoy', (
    tester,
  ) async {
    expect(
      ReporteDiarioView.etiquetaFecha(DateTime(2026, 11, 11), esHoy: true),
      'Hoy, mié. 11 nov.',
    );
    expect(
      ReporteDiarioView.etiquetaFecha(DateTime(2026, 11, 1), esHoy: false),
      'dom. 1 nov.',
    );
    expect(Decimal.zero, d('0'));
  });
}
