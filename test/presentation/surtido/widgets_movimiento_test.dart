import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';

void main() {
  Future<void> montar(
    WidgetTester tester,
    Widget hijo, {
    Size tamano = const Size(800, 600),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: Scaffold(body: Center(child: hijo)),
      ),
    );
  }

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
        unidad: 'und',
        onCambio: (_) {},
        onSumar: (_) {},
      ),
    );

    testWidgets('− y + en pasoFondo, más oscuros con el mouse', (tester) async {
      await montar(tester, selector());
      final menos = find.byKey(const Key('p_cantidad_menos'));

      expect(fondoDe(tester, menos), ColoresGip.pasoFondo);
      expect(tester.getSize(menos), const Size.square(60));
      final icono = tester.widget<IconTheme>(
        find.descendant(of: menos, matching: find.byType(IconTheme)).last,
      );
      expect(icono.data.color, ColoresGip.texto);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(menos));
      await tester.pumpAndSettle();
      expect(fondoDe(tester, menos), ColoresGip.pasoFondoActivo);
    });

    testWidgets('el número en Archivo 800 de 38 px con la unidad', (
      tester,
    ) async {
      await montar(tester, selector());
      final campo = tester.widget<TextField>(
        find.byKey(const Key('p_cantidad')),
      );
      expect(campo.style!.fontFamily, TipografiaGip.titulos);
      expect(campo.style!.fontWeight, FontWeight.w800);
      expect(campo.style!.fontSize, 38);
      expect(find.text('und'), findsOneWidget);
      // La unidad va justo después del número, no en el borde de la caja.
      expect(
        tester.getTopLeft(find.text('und')).dx -
            tester.getTopRight(find.byKey(const Key('p_cantidad'))).dx,
        lessThan(16),
      );
    });

    testWidgets('los botones avisan el paso', (tester) async {
      final pasos = <int>[];
      await montar(
        tester,
        SizedBox(
          width: 360,
          child: SelectorCantidad(
            prefijoClave: 'p',
            controlador: controlador,
            habilitado: true,
            onCambio: (_) {},
            onSumar: pasos.add,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Agregar una'));
      await tester.tap(find.byTooltip('Quitar una'));
      expect(pasos, [1, -1]);
    });
  });

  group('PanelProducto', () {
    testWidgets('sin producto: ícono de paquete y "Elegir producto"', (
      tester,
    ) async {
      await montar(
        tester,
        PanelProducto(
          prefijoClave: 'p',
          producto: null,
          textoSinProducto: '¿Qué producto sale?',
          existencia: 'Hay 14',
          habilitado: true,
          onElegir: () {},
        ),
      );
      expect(find.byType(IconoPaquete), findsOneWidget);
      expect(find.text('PRODUCTO'), findsOneWidget);
      expect(find.text('¿Qué producto sale?'), findsOneWidget);
      expect(find.text('Búsquelo por el nombre'), findsOneWidget);
      expect(find.text('Elegir producto'), findsOneWidget);
      // Sin producto no se muestra la existencia.
      expect(find.text('Hay 14'), findsNothing);
    });
  });

  testWidgets('PanelesProductoCantidad: lado a lado o uno debajo del otro', (
    tester,
  ) async {
    Widget paneles(double ancho) => SizedBox(
      width: ancho,
      child: const PanelesProductoCantidad(
        producto: Text('producto'),
        cantidad: Text('cantidad'),
      ),
    );
    await montar(tester, paneles(700));
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('producto')).dy,
      tester.getTopLeft(find.text('cantidad')).dy,
    );

    await montar(tester, paneles(400));
    expect(find.byType(VerticalDivider), findsNothing);
    expect(
      tester.getTopLeft(find.text('cantidad')).dy,
      greaterThan(tester.getTopLeft(find.text('producto')).dy),
    );
  });

  testWidgets('AtajoCantidad es una píldora que se toca', (tester) async {
    var tocado = 0;
    await montar(
      tester,
      AtajoCantidad(texto: 'Todas (14)', onPressed: () => tocado++),
    );
    await tester.tap(find.text('Todas (14)'));
    expect(tocado, 1);
    final boton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(boton.style!.shape!.resolve({}), isA<StadiumBorder>());
  });

  testWidgets('ColumnasMovimiento pone el resumen al lado o debajo', (
    tester,
  ) async {
    Widget columnas(double ancho) => SizedBox(
      width: ancho,
      child: const ColumnasMovimiento(
        formulario: Text('formulario'),
        resumen: Text('resumen'),
      ),
    );
    await montar(tester, columnas(1100), tamano: const Size(1200, 600));
    expect(
      tester.getTopLeft(find.text('resumen')).dx,
      greaterThan(tester.getTopLeft(find.text('formulario')).dx),
    );

    await montar(tester, columnas(700));
    expect(
      tester.getTopLeft(find.text('resumen')).dy,
      greaterThan(tester.getTopLeft(find.text('formulario')).dy),
    );
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
}
