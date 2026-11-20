import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/vender/dialogo_cantidad.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);

  /// Muestra un botón que abre el diálogo y guarda lo que devuelve.
  Future<void> montar(
    WidgetTester tester, {
    UnidadMedida unidad = UnidadMedida.kilogramo,
    Decimal? actual,
    Size tamano = const Size(360, 640),
    required void Function(Decimal?) alTerminar,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('abrir'),
              onPressed: () async => alTerminar(
                await pedirCantidad(
                  context,
                  producto: 'Yuca',
                  unidad: unidad,
                  actual: actual ?? d('1'),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
  }

  Future<void> escribir(WidgetTester tester, String texto) async {
    await tester.enterText(
      find.byKey(const Key('dialogo_cantidad_campo')),
      texto,
    );
    await tester.pump();
  }

  Future<void> aceptar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('dialogo_cantidad_aceptar')));
    await tester.pumpAndSettle();
  }

  String? textoDelCampo(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('dialogo_cantidad_campo')))
      .controller
      ?.text;

  testWidgets('pregunta por kilos, muestra la unidad y la cantidad de ahora', (
    tester,
  ) async {
    await montar(tester, actual: d('2.5'), alTerminar: (_) {});

    expect(find.text('¿Cuántos kilos de Yuca?'), findsOneWidget);
    expect(find.text('Cantidad en kg'), findsOneWidget);
    expect(textoDelCampo(tester), '2,5');
  });

  testWidgets('por libra pregunta por libras', (tester) async {
    await montar(tester, unidad: UnidadMedida.libra, alTerminar: (_) {});

    expect(find.text('¿Cuántas libras de Yuca?'), findsOneWidget);
    expect(find.text('Cantidad en lb'), findsOneWidget);
  });

  testWidgets('en kilos acepta decimales con coma y devuelve el número', (
    tester,
  ) async {
    Decimal? resultado;
    await montar(tester, alTerminar: (v) => resultado = v);

    await escribir(tester, '3,4');
    await aceptar(tester);

    expect(resultado, d('3.4'));
    expect(find.byKey(const Key('dialogo_cantidad')), findsNothing);
  });

  testWidgets('en kilos acepta también el punto', (tester) async {
    Decimal? resultado;
    await montar(tester, alTerminar: (v) => resultado = v);

    await escribir(tester, '0.125');
    await aceptar(tester);

    expect(resultado, d('0.125'));
  });

  testWidgets('por unidad el campo solo deja escribir números enteros', (
    tester,
  ) async {
    Decimal? resultado;
    await montar(
      tester,
      unidad: UnidadMedida.unidad,
      alTerminar: (v) => resultado = v,
    );

    await escribir(tester, '2,5');
    expect(textoDelCampo(tester), '25');
    await aceptar(tester);

    expect(resultado, d('25'));
  });

  testWidgets('el campo no deja escribir letras', (tester) async {
    await montar(tester, alTerminar: (_) {});

    await escribir(tester, 'a3,4b');

    expect(textoDelCampo(tester), '3,4');
  });

  testWidgets('por unidad la pregunta es "Cuántas unidades"', (tester) async {
    await montar(tester, unidad: UnidadMedida.unidad, alTerminar: (_) {});

    expect(find.text('¿Cuántas unidades de Yuca?'), findsOneWidget);
  });

  for (final (texto, mensaje) in [
    ('', 'Escriba la cantidad'),
    ('0', 'La cantidad debe ser mayor que cero'),
    ('1,2345', 'Use máximo 3 decimales'),
  ]) {
    testWidgets('"$texto" muestra "$mensaje" y no cierra', (tester) async {
      Decimal? resultado = d('999');
      await montar(tester, alTerminar: (v) => resultado = v);

      await escribir(tester, texto);
      await aceptar(tester);

      expect(find.text(mensaje), findsOneWidget);
      expect(find.byKey(const Key('dialogo_cantidad')), findsOneWidget);
      expect(resultado, d('999'), reason: 'todavía no terminó');
    });
  }

  testWidgets('el error se quita al volver a escribir', (tester) async {
    await montar(tester, alTerminar: (_) {});
    await escribir(tester, '0');
    await aceptar(tester);
    expect(find.text('La cantidad debe ser mayor que cero'), findsOneWidget);

    await escribir(tester, '2');

    expect(find.text('La cantidad debe ser mayor que cero'), findsNothing);
  });

  testWidgets('Cancelar devuelve null', (tester) async {
    Decimal? resultado = d('999');
    await montar(tester, alTerminar: (v) => resultado = v);

    await tester.tap(find.byKey(const Key('dialogo_cantidad_cancelar')));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
    expect(find.byKey(const Key('dialogo_cantidad')), findsNothing);
  });

  testWidgets('el botón del teclado también acepta', (tester) async {
    Decimal? resultado;
    await montar(tester, alTerminar: (v) => resultado = v);

    await escribir(tester, '2,75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(resultado, d('2.75'));
  });

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('a ${tamano.width.toInt()} px no se desborda y los botones '
        'miden 44 px o más', (tester) async {
      await montar(tester, tamano: tamano, alTerminar: (_) {});

      expect(tester.takeException(), isNull);
      for (final clave in [
        'dialogo_cantidad_aceptar',
        'dialogo_cantidad_cancelar',
      ]) {
        expect(
          tester.getSize(find.byKey(Key(clave))).height,
          greaterThanOrEqualTo(44),
        );
      }
    });
  }
}
