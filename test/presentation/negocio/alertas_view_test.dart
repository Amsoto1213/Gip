import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/alertas_view.dart';
import 'package:gip/presentation/negocio/alertas_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'alertas_falsos.dart';
import 'datos_alertas.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  Future<void> abrir(
    WidgetTester tester,
    Size tamano, {
    List<AlertaReabastecimiento>? alertas,
    List<VentaPerdida>? perdidas,
    UsuarioActivo? usuario,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final coordinador = ConsultarAlertasFalso();
    when(() => coordinador.consultarAlertas(any(), any(), any()))
        .thenAnswer((invocacion) async {
          if (invocacion.positionalArguments[2] == empleadoAlertas.usuario) {
            throw const ExcepcionSoloPropietario();
          }
          return alertas ?? alertasDelMockup;
        });
    when(() => coordinador.consultarVentasPerdidas(any(), any(), any(), any()))
        .thenAnswer((_) async => perdidas ?? ventasPerdidasDelMockup);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => AlertasViewModel(
            coordinador,
            usuario ?? propietariaAlertas,
            reloj: () => DateTime(2026, 11, 15, 9),
          )..cargar(),
          child: const AlertasView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? colorDe(WidgetTester tester, String texto) =>
      tester.widget<Text>(find.text(texto)).style?.color;

  testWidgets('móvil: cada alerta con sus días en rojo y su sustento', (
    tester,
  ) async {
    await abrir(tester, movil);
    final esquema = Theme.of(tester.element(find.byType(AlertasView)))
        .colorScheme;

    expect(find.text('Alertas de surtido'), findsWidgets);
    expect(
      find.text('Calculadas hoy. Son sugerencias: usted decide qué comprar.'),
      findsOneWidget,
    );
    expect(find.text('Por surtir · 3'), findsOneWidget);
    expect(find.text('Ventas perdidas · 3'), findsOneWidget);
    expect(find.text('Coco'), findsOneWidget);
    expect(find.text('3 veces'), findsOneWidget);
    expect(find.text('2,3'), findsOneWidget);
    // 0,86 días: se trunca a 0,8 y va en rojo.
    expect(find.text('0,8'), findsOneWidget);
    expect(colorDe(tester, '0,8'), esquema.error);
    expect(find.text('4'), findsOneWidget);
    expect(find.widgetWithText(PildoraEstado, 'Provisional'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(NotaInfo), 200);
    expect(find.byType(NotaInfo), findsOneWidget);
    expect(find.text('Urgente'), findsNothing);
    expect(find.text('Armar lista de pedido'), findsNothing);
  });

  testWidgets('web: tabla con las columnas de wAlertas y Cómo leerlas', (
    tester,
  ) async {
    await abrir(tester, web);
    final esquema = Theme.of(tester.element(find.byType(AlertasView)))
        .colorScheme;

    for (final columna in [
      'PRODUCTO',
      'HAY',
      'VENDE AL DÍA',
      'SE FUERON SIN COMPRAR',
      'ALCANZA PARA',
    ]) {
      expect(find.text(columna), findsOneWidget);
    }
    expect(find.text('0,8 días'), findsOneWidget);
    expect(colorDe(tester, '0,8 días'), esquema.error);
    expect(find.text('1,8 días'), findsOneWidget);
    expect(find.text('4 días'), findsOneWidget);
    expect(find.text('Cómo leerlas'), findsOneWidget);
    expect(find.byType(NotaInfo), findsOneWidget);
  });

  testWidgets('sin alertas muestra el mensaje del diagrama', (tester) async {
    await abrir(tester, movil, alertas: const [], perdidas: const []);

    expect(find.text('No hay productos por agotarse'), findsOneWidget);
    expect(find.text('Por surtir · 0'), findsOneWidget);
    expect(find.byType(NotaInfo), findsNothing);
  });

  testWidgets('al empleado le muestra que es solo para el propietario', (
    tester,
  ) async {
    await abrir(tester, movil, usuario: empleadoAlertas);

    expect(
      find.widgetWithText(
        TarjetaAviso,
        'Esta consulta es solo para el propietario',
      ),
      findsOneWidget,
    );
    expect(find.text('Coco'), findsNothing);
    expect(find.textContaining('Por surtir'), findsNothing);
  });

  testWidgets('la pestaña Ventas perdidas lista producto y fecha', (
    tester,
  ) async {
    await abrir(tester, movil);

    await tester.tap(find.text('Ventas perdidas · 3'));
    await tester.pumpAndSettle();

    expect(find.text('Coco'), findsNWidgets(3));
    expect(find.text('14 nov. · 6:05 p. m.'), findsOneWidget);
  });

  testWidgets('sin ventas perdidas lo dice', (tester) async {
    await abrir(tester, movil, perdidas: const []);

    await tester.tap(find.text('Ventas perdidas · 0'));
    await tester.pumpAndSettle();

    expect(
      find.text('No hubo ventas perdidas en los últimos 30 días'),
      findsOneWidget,
    );
  });

  for (final tamano in [movil, const Size(800, 700), web]) {
    testWidgets('sin desbordes en ${tamano.width.toInt()}×'
        '${tamano.height.toInt()}', (tester) async {
      await abrir(tester, tamano);
      expect(tester.takeException(), isNull);
      await tester.tap(find.textContaining('Ventas perdidas'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('las pestañas miden al menos 44 px', (tester) async {
    await abrir(tester, movil);

    expect(
      tester.getSize(find.byKey(const Key('alertas_pestana_0'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  group('formatos', () {
    test('existencia con miles y coma', () {
      expect(mostrarExistencia(d('1250')), '1.250');
      expect(mostrarExistencia(d('2.5')), '2,5');
    });

    test('consumo con un decimal', () {
      expect(mostrarConsumo(d('2')), '2,0');
      expect(mostrarConsumo(d('9.4667')), '9,5');
    });

    test('días truncados: 6,99 no se muestra como 7', () {
      expect(mostrarDias(d('6.99')), '6,9 días');
      expect(mostrarDias(d('1')), '1 día');
      expect(mostrarDias(d('2')), '2 días');
      expect(mostrarDias(d('0')), '0 días');
      expect(mostrarDias(d('-3')), '0 días');
    });

    test('fecha y hora local', () {
      expect(
        mostrarFechaHora(DateTime(2026, 11, 3, 0, 7)),
        '3 nov. · 12:07 a. m.',
      );
      expect(
        mostrarFechaHora(DateTime(2026, 1, 9, 12, 30)),
        '9 ene. · 12:30 p. m.',
      );
    });
  });
}
