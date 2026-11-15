import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/barra_inferior.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

final List<SeccionNavegacion> secciones = [
  (
    etiqueta: 'Vender',
    icono: (t) => Icon(Icons.shopping_bag_outlined, size: t),
    subsecciones: const [],
  ),
  (
    etiqueta: 'Surtido',
    icono: (t) => Icon(Icons.inventory_2_outlined, size: t),
    subsecciones: const [
      (etiqueta: 'Entrada de mercancía', ruta: '/surtido/entrada'),
      (etiqueta: 'Pérdida o devolución', ruta: '/surtido/perdida'),
    ],
  ),
];

Future<void> montar(WidgetTester tester, Widget hijo, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaGip.claro(),
      home: Scaffold(body: hijo),
    ),
  );
}

void main() {
  group('MenuLateral', () {
    Widget menu({
      int activo = 1,
      String ruta = '/surtido/perdida',
      ValueChanged<int>? onSeccion,
      ValueChanged<Subseccion>? onSubseccion,
      String usuario = 'Luis Alberto Pérez',
    }) => Row(
      children: [
        MenuLateral(
          secciones: secciones,
          indiceActivo: activo,
          rutaActual: ruta,
          onSeccion: onSeccion ?? (_) {},
          onSubseccion: onSubseccion ?? (_) {},
          tienda: 'Tienda Doña Rosa',
          direccion: 'Calle 30 # 12-4, Turbaco',
          usuario: usuario,
          rol: 'Empleado',
        ),
      ],
    );

    testWidgets('muestra tienda, usuario, iniciales y rol', (tester) async {
      await montar(tester, menu(), const Size(1280, 800));
      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('Calle 30 # 12-4, Turbaco'), findsOneWidget);
      expect(find.text('Luis Alberto Pérez'), findsOneWidget);
      expect(find.text('LA'), findsOneWidget);
      expect(find.text('Empleado'), findsOneWidget);
      expect(find.text('GIP'), findsOneWidget);
      expect(tester.getSize(find.byType(MenuLateral)).width, MenuLateral.ancho);
    });

    testWidgets('marca la subsección activa y avisa los toques', (
      tester,
    ) async {
      int? seccion;
      Subseccion? sub;
      await montar(
        tester,
        menu(onSeccion: (i) => seccion = i, onSubseccion: (s) => sub = s),
        const Size(1280, 800),
      );
      expect(
        tester.getSemantics(find.text('Pérdida o devolución')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('Entrada de mercancía')),
        isSemantics(isSelected: false),
      );
      await tester.tap(find.text('Entrada de mercancía'));
      expect(sub?.ruta, '/surtido/entrada');
      await tester.tap(find.text('Vender'));
      expect(seccion, 0);
    });

    testWidgets('sin la sección activa no muestra sus subsecciones', (
      tester,
    ) async {
      await montar(
        tester,
        menu(activo: 0, ruta: '/vender'),
        const Size(1280, 800),
      );
      expect(find.text('Entrada de mercancía'), findsNothing);
    });

    testWidgets('en una ventana baja se desplaza sin desbordar', (
      tester,
    ) async {
      await montar(tester, menu(), const Size(1280, 360));
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('un nombre de una palabra da una inicial', (tester) async {
      await montar(tester, menu(usuario: 'carmen'), const Size(1280, 800));
      expect(find.text('C'), findsOneWidget);
    });
  });

  testWidgets('BarraInferior: 76 px, píldora en la activa y toques', (
    tester,
  ) async {
    int? tocada;
    await montar(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: BarraInferior(
          secciones: secciones,
          indiceActivo: 1,
          onSeccion: (i) => tocada = i,
        ),
      ),
      const Size(390, 844),
    );
    expect(
      tester.getSize(find.byType(BarraInferior)).height,
      BarraInferior.alto,
    );
    final pildora = tester.widget<Container>(
      find.byKey(const Key('barra_inferior_activa')),
    );
    expect(
      (pildora.decoration! as BoxDecoration).color,
      ColoresGip.primarioSuave,
    );
    expect(
      tester.widget<Text>(find.text('Surtido')).style?.color,
      ColoresGip.primario,
    );
    await tester.tap(find.text('Vender'));
    expect(tocada, 0);
  });
}
