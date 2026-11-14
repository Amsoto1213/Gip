import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';

void main() {
  Future<void> montar(WidgetTester tester, Widget hijo) => tester.pumpWidget(
    MaterialApp(
      theme: TemaGip.claro(),
      home: Scaffold(body: Center(child: hijo)),
    ),
  );

  /// Color de fondo que pinta el botón − en este momento.
  Color fondoDe(WidgetTester tester, Finder boton) {
    final material = tester.widget<Material>(
      find.descendant(of: boton, matching: find.byType(Material)).first,
    );
    return material.color!;
  }

  group('SelectorCantidad', () {
    late TextEditingController controlador;
    setUp(() => controlador = TextEditingController(text: '2'));
    tearDown(() => controlador.dispose());

    Widget selector({bool habilitado = true}) => SizedBox(
      width: 360,
      child: SelectorCantidad(
        prefijoClave: 'p',
        controlador: controlador,
        habilitado: habilitado,
        onCambio: (_) {},
        onSumar: (_) {},
      ),
    );

    testWidgets('− y + son grises claros con ícono oscuro y cambian con el '
        'mouse y al presionar', (tester) async {
      await montar(tester, selector());
      final menos = find.byKey(const Key('p_cantidad_menos'));

      expect(fondoDe(tester, menos), ColoresGip.fondo);
      final icono = tester.widget<IconTheme>(
        find.descendant(of: menos, matching: find.byType(IconTheme)).last,
      );
      expect(icono.data.color, ColoresGip.texto);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(menos));
      await tester.pumpAndSettle();
      expect(fondoDe(tester, menos), ColoresGip.borde);

      final toque = await tester.startGesture(tester.getCenter(menos));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fondoDe(tester, menos), ColoresGip.bordeFuerte);
      await toque.up();
      await tester.pumpAndSettle();
    });

    testWidgets('el número va en la tipografía de títulos, grande', (
      tester,
    ) async {
      await montar(tester, selector());
      final campo = tester.widget<TextField>(
        find.byKey(const Key('p_cantidad')),
      );
      expect(campo.style!.fontFamily, TipografiaGip.titulos);
      expect(campo.style!.fontWeight, FontWeight.w800);
      expect(campo.style!.fontSize, 40);
    });
  });

  testWidgets('FilaResumen: valor en negrita y el destacado en Archivo', (
    tester,
  ) async {
    await montar(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilaResumen('Salen', '− 2 und'),
          FilaResumen('Quedará en', '12 und', destacada: true),
        ],
      ),
    );
    final valor = tester.widget<Text>(find.text('− 2 und'));
    expect(valor.style!.fontWeight, FontWeight.w700);
    final destacado = tester.widget<Text>(find.text('12 und'));
    expect(destacado.style!.fontFamily, TipografiaGip.titulos);
    expect(destacado.style!.fontSize, 23);
  });

  testWidgets('la tarjeta del producto usa el ícono de paquete', (
    tester,
  ) async {
    await montar(
      tester,
      TarjetaProductoMovimiento(
        prefijoClave: 'p',
        producto: null,
        detalle: '',
        textoSinProducto: '¿Qué producto sale?',
        habilitado: true,
        onElegir: () {},
      ),
    );
    expect(find.byType(IconoPaquete), findsOneWidget);
  });
}
