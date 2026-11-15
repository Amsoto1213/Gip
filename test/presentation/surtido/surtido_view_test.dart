import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';

void main() {
  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: TemaGip.claro(), home: const SurtidoView()),
    );
  }

  testWidgets('móvil: título, contexto fijo, + cuadrado y acciones', (
    tester,
  ) async {
    await abrir(tester, const Size(390, 844));

    expect(find.text('Surtido'), findsOneWidget);
    expect(find.text(SurtidoView.contexto), findsOneWidget);
    expect(find.byType(BotonIconoPrimario), findsOneWidget);
    expect(find.byTooltip('Producto nuevo'), findsOneWidget);
    expect(find.text('Buscar en el surtido…'), findsOneWidget);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Pérdida'), findsOneWidget);
    expect(find.text('Conteo'), findsOneWidget);
    // El lector (CUS-17) y la tabla (CUS-25) aún no están.
    expect(find.byTooltip('Leer código con el lector'), findsNothing);
    expect(find.text('Existencias'), findsNothing);
    expect(find.byType(TarjetaAccion), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('web: botón Producto nuevo y acciones con descripción', (
    tester,
  ) async {
    await abrir(tester, const Size(1180, 900));

    expect(
      find.widgetWithText(BotonPrimario, 'Producto nuevo'),
      findsOneWidget,
    );
    expect(find.text('Buscar producto por nombre…'), findsOneWidget);
    expect(find.text('Registrar entrada'), findsOneWidget);
    expect(find.text('Llegó mercancía del proveedor'), findsOneWidget);
    expect(find.text('Registrar pérdida'), findsOneWidget);
    expect(find.text('Vencido, dañado o devuelto'), findsOneWidget);
    expect(find.text('Conteo físico'), findsOneWidget);
    expect(find.text('Cuente y corrija la existencia'), findsOneWidget);
    expect(tester.getSize(find.byType(BarraBusqueda)).height, 58);
  });

  testWidgets('en un teléfono de 5" no se desborda', (tester) async {
    await abrir(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
