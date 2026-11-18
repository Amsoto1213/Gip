import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/contador_entero.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

void main() {
  Future<void> montar(
    WidgetTester tester,
    int valor,
    ValueChanged<int>? onCambio,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: Scaffold(
          body: ContadorEntero(valor: valor, maximo: 5, onCambio: onCambio),
        ),
      ),
    );
  }

  testWidgets('muestra el valor y sube o baja de uno en uno', (tester) async {
    final cambios = <int>[];
    await montar(tester, 3, cambios.add);

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contador_mas')));
    await tester.tap(find.byKey(const Key('contador_menos')));

    expect(cambios, [4, 2]);
  });

  testWidgets('desactiva "−" en el mínimo y "+" en el máximo', (tester) async {
    await montar(tester, 1, (_) {});
    expect(
      tester
          .widget<BotonIconoSecundario>(find.byKey(const Key('contador_menos')))
          .onPressed,
      isNull,
    );

    await montar(tester, 5, (_) {});
    expect(
      tester
          .widget<BotonIconoSecundario>(find.byKey(const Key('contador_mas')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('sin onCambio queda desactivado y con áreas de 44 px', (
    tester,
  ) async {
    await montar(tester, 3, null);

    for (final clave in ['contador_menos', 'contador_mas']) {
      final boton = find.byKey(Key(clave));
      expect(tester.widget<BotonIconoSecundario>(boton).onPressed, isNull);
      expect(tester.getSize(boton).shortestSide, greaterThanOrEqualTo(44));
    }
  });
}
