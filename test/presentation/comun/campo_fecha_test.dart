import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/campo_fecha.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

void main() {
  Future<void> montar(
    WidgetTester tester,
    Widget hijo, {
    double ancho = 360,
  }) async {
    tester.view.physicalSize = Size(ancho, 640);
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

  group('textoDia', () {
    test('día, mes abreviado y año', () {
      expect(textoDia(DateTime(2026, 10, 1)), '1 oct. 2026');
      expect(textoDia(DateTime(2026, 1, 31)), '31 ene. 2026');
      expect(textoDia(DateTime(2027, 12, 5)), '5 dic. 2027');
    });
  });

  group('CampoFecha', () {
    testWidgets('muestra la etiqueta y el día elegido', (tester) async {
      await montar(
        tester,
        CampoFecha(
          etiqueta: 'Desde',
          fecha: DateTime(2026, 10, 1),
          onTap: () {},
        ),
      );

      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('1 oct. 2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('tocarlo llama a onTap y mide 44 px o más', (tester) async {
      var toques = 0;
      await montar(
        tester,
        CampoFecha(
          etiqueta: 'Hasta',
          fecha: DateTime(2026, 10, 31),
          onTap: () => toques++,
        ),
      );

      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('31 oct. 2026'));
      expect(toques, 1);
    });

    testWidgets('sin onTap no responde', (tester) async {
      await montar(
        tester,
        CampoFecha(
          etiqueta: 'Hasta',
          fecha: DateTime(2026, 10, 31),
          onTap: null,
        ),
      );

      await tester.tap(find.text('31 oct. 2026'));

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.byType(CampoFecha)),
        isNot(
          matchesSemantics(label: 'Hasta: 31 oct. 2026', hasTapAction: true),
        ),
      );
    });

    testWidgets('con error lo muestra debajo y marca el borde en rojo', (
      tester,
    ) async {
      await montar(
        tester,
        CampoFecha(
          etiqueta: 'Desde',
          fecha: DateTime(2026, 11, 5),
          onTap: () {},
          error: 'La fecha inicial no puede ser posterior a la final',
        ),
      );

      expect(
        find.text('La fecha inicial no puede ser posterior a la final'),
        findsOneWidget,
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(CampoFecha),
              matching: find.byType(Material),
            )
            .first,
      );
      final borde = (material.shape! as RoundedRectangleBorder).side;
      expect(borde.color, TemaGip.claro().colorScheme.error);
    });

    testWidgets('en 360 px no se desborda con un día largo', (tester) async {
      await montar(
        tester,
        Row(
          children: [
            Expanded(
              child: CampoFecha(
                etiqueta: 'Desde',
                fecha: DateTime(2026, 12, 31),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoFecha(
                etiqueta: 'Hasta',
                fecha: DateTime(2026, 12, 31),
                onTap: () {},
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
