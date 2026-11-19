import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/casilla_registro.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

void main() {
  Future<void> montar(WidgetTester tester, Widget hijo) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: hijo),
        ),
      ),
    );
  }

  testWidgets('muestra el título y el detalle', (tester) async {
    await montar(
      tester,
      CasillaRegistro(
        titulo: 'Entrada de las 10:42',
        detalle: '24 huevos · FV-1',
        marcada: false,
        onCambio: (_) {},
      ),
    );

    expect(find.text('Entrada de las 10:42'), findsOneWidget);
    expect(find.text('24 huevos · FV-1'), findsOneWidget);
  });

  testWidgets('sin marcar no tiene palomita; marcada, sí', (tester) async {
    await montar(
      tester,
      CasillaRegistro(titulo: 'A', marcada: false, onCambio: (_) {}),
    );
    expect(find.byIcon(Icons.check), findsNothing);

    await montar(
      tester,
      CasillaRegistro(titulo: 'A', marcada: true, onCambio: (_) {}),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tocarla avisa con el valor contrario', (tester) async {
    final valores = <bool>[];
    await montar(
      tester,
      CasillaRegistro(titulo: 'A', marcada: false, onCambio: valores.add),
    );
    await tester.tap(find.text('A'));

    await montar(
      tester,
      CasillaRegistro(titulo: 'A', marcada: true, onCambio: valores.add),
    );
    await tester.tap(find.text('A'));

    expect(valores, [true, false]);
  });

  testWidgets('mide 44 px o más', (tester) async {
    await montar(
      tester,
      CasillaRegistro(titulo: 'A', marcada: false, onCambio: (_) {}),
    );

    expect(
      tester.getSize(find.byType(CasillaRegistro)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('sin onCambio no responde y queda deshabilitada', (tester) async {
    await montar(
      tester,
      const CasillaRegistro(titulo: 'A', marcada: false, onCambio: null),
    );

    await tester.tap(find.text('A'));

    expect(tester.takeException(), isNull);
    expect(
      tester.getSemantics(find.byType(CasillaRegistro)),
      isNot(matchesSemantics(hasTapAction: true)),
    );
  });

  testWidgets('con título largo en 360 px no se desborda', (tester) async {
    await montar(
      tester,
      CasillaRegistro(
        titulo:
            'Venta del computador de la caja con un nombre muy largo que no '
            'cabe en una sola línea de la pantalla',
        detalle: '10:42:31 a. m. · efectivo · leche, huevos, arroz, azúcar',
        marcada: true,
        onCambio: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
