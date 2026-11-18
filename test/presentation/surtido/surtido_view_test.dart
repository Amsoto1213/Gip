import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/chip_estado.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/existencias_view_model.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:provider/provider.dart';

import 'datos_existencias.dart';
import 'existencias_falsos.dart';

/// Surtido con las existencias (CUS-25), en el móvil y en la web.
void main() {
  late ConsultarExistenciasFalso coordinador;

  setUp(() => coordinador = coordinadorExistencias());

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => ExistenciasViewModel(
            coordinador,
            tiendaExistencias,
            reloj: ahoraExistencias,
          )..cargar(),
          child: const SurtidoView(reloj: ahoraExistencias),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fila(String productoId) =>
      find.byKey(ValueKey('existencias_fila_$productoId'));

  Finder detalle(String productoId) =>
      find.byKey(ValueKey('existencias_detalle_$productoId'));

  Finder movimiento(String id) =>
      find.byKey(ValueKey('existencias_movimiento_$id'));

  /// Toca la fila del producto (el nombre, que está dentro de ella).
  Future<void> tocarProducto(WidgetTester tester, String nombre) async {
    await tester.ensureVisible(find.text(nombre));
    await tester.tap(find.text(nombre));
    await tester.pumpAndSettle();
  }

  group('móvil 360×640', () {
    testWidgets('encabezado, acciones, filtros y un producto por fila', (
      tester,
    ) async {
      await abrir(tester, const Size(360, 640));

      expect(find.text('Surtido'), findsOneWidget);
      expect(find.text('3 productos'), findsOneWidget);
      expect(find.byTooltip('Producto nuevo'), findsOneWidget);
      expect(find.text('Buscar en el surtido…'), findsOneWidget);
      expect(find.byType(TarjetaAccion), findsNWidgets(3));
      expect(find.text('Todos · 3'), findsOneWidget);
      expect(find.text('Agotados · 1'), findsOneWidget);
      expect(find.text('Por peso'), findsOneWidget);
      // Sin "Poco" ni valor del inventario (DI-32). El botón del lector abre
      // la cámara en la app Android (DI-34); las pruebas corren como Android.
      expect(find.textContaining('Poco'), findsNothing);
      expect(find.textContaining('valor'), findsNothing);
      expect(find.byTooltip('Leer código con la cámara'), findsOneWidget);

      await tester.ensureVisible(fila(queso.getId()));
      expect(find.text('Aceite 1 L'), findsOneWidget);
      expect(find.text('Unidad · \$ 9.900'), findsOneWidget);
      expect(find.text('Libra · \$ 9.000'), findsOneWidget);
      expect(
        find.descendant(of: fila(aceite.getId()), matching: find.text('32')),
        findsOneWidget,
      );
      // Solo el queso, con existencia cero, lleva "Agotado".
      expect(find.byType(ChipEstado), findsOneWidget);
      expect(
        find.descendant(
          of: fila(queso.getId()),
          matching: find.byType(ChipEstado),
        ),
        findsOneWidget,
      );
      // En el móvil no hay columna de último movimiento.
      expect(find.text('Último movimiento'.toUpperCase()), findsNothing);
      expect(coordinador.consultas, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar un producto muestra sus 3 últimos movimientos', (
      tester,
    ) async {
      await abrir(tester, const Size(360, 640));

      await tocarProducto(tester, 'Aceite 1 L');

      expect(detalle(aceite.getId()), findsOneWidget);
      expect(find.text('Últimos movimientos'), findsOneWidget);
      expect(find.text('Hoy 4:10 p. m. · Entrada FV-10231'), findsOneWidget);
      expect(find.text('+24'), findsOneWidget);
      expect(find.text('Hoy 10:15 a. m. · Venta'), findsOneWidget);
      expect(find.text('Ayer 7:40 p. m. · Conteo'), findsOneWidget);
      // Solo los 3 más recientes; el anulado del 9 de noviembre no cabe.
      expect(movimiento('m-anulada'), findsNothing);
      // "Ver historial completo" llega después (DI-32).
      expect(find.text('Ver historial completo'), findsNothing);

      await tocarProducto(tester, 'Aceite 1 L');
      expect(detalle(aceite.getId()), findsNothing);
    });

    testWidgets('un producto sin movimientos lo dice', (tester) async {
      await abrir(tester, const Size(360, 640));

      await tocarProducto(tester, 'Arroz 500 g');

      expect(
        find.text('Sin movimientos en los últimos 30 días'),
        findsOneWidget,
      );
    });

    testWidgets('un movimiento anulado lleva su píldora', (tester) async {
      coordinador.movimientos[aceite.getId()] = movimientosAceite()
          .where((m) => m.getId() == 'm-anulada')
          .toList();
      await abrir(tester, const Size(360, 640));

      await tocarProducto(tester, 'Aceite 1 L');

      expect(
        find.text('9 nov. 8:00 a. m. · Pérdida (vencido)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(PildoraEstado, 'Anulado'), findsOneWidget);
      expect(find.text('−2'), findsOneWidget);
    });

    testWidgets('filtros Agotados y Por peso', (tester) async {
      await abrir(tester, const Size(360, 640));

      await tester.tap(find.text('Agotados · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Queso costeño'), findsOneWidget);
      expect(find.text('Aceite 1 L'), findsNothing);

      await tester.tap(find.text('Por peso'));
      await tester.pumpAndSettle();
      expect(find.text('Queso costeño'), findsOneWidget);
      expect(find.text('Arroz 500 g'), findsNothing);

      coordinador.items = [itemAceite];
      await tester.tap(find.text('Todos · 3'));
      await tester.pumpAndSettle();
      expect(find.text('Arroz 500 g'), findsOneWidget);
    });
  });

  group('web 1280×800', () {
    testWidgets('tabla con código, unidad, precio, hay y último movimiento', (
      tester,
    ) async {
      await abrir(tester, const Size(1280, 800));

      expect(
        find.widgetWithText(BotonPrimario, 'Producto nuevo'),
        findsOneWidget,
      );
      expect(find.text('Buscar producto por nombre…'), findsOneWidget);
      expect(tester.getSize(find.byType(BarraBusqueda)).height, 58);
      expect(find.text('Existencias'), findsOneWidget);
      for (final columna in [
        'PRODUCTO',
        'UNIDAD',
        'PRECIO',
        'HAY',
        'ÚLTIMO MOVIMIENTO',
      ]) {
        expect(find.text(columna), findsOneWidget);
      }
      expect(find.text('P014'), findsOneWidget);
      expect(find.text('\$ 9.900'), findsOneWidget);
      expect(find.text('Libra'), findsOneWidget);

      // Cada fila consultó su último movimiento.
      expect(coordinador.consultas.map((c) => c.producto.getNombre()).toSet(), {
        'Aceite 1 L',
        'Arroz 500 g',
        'Queso costeño',
      });
      final ultimo = tester.widget<Text>(
        find.byKey(ValueKey('existencias_ultimo_${aceite.getId()}')),
      );
      expect(ultimo.data, 'Entrada · hoy 4:10 p. m.');
      final sinMovimientos = tester.widget<Text>(
        find.byKey(ValueKey('existencias_ultimo_${arroz.getId()}')),
      );
      expect(sinMovimientos.data, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar una fila despliega los últimos movimientos', (
      tester,
    ) async {
      await abrir(tester, const Size(1280, 800));

      await tocarProducto(tester, 'Aceite 1 L');

      expect(detalle(aceite.getId()), findsOneWidget);
      expect(find.text('Hoy 4:10 p. m. · Entrada FV-10231'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('sin productos lo dice', (tester) async {
    coordinador.items = [];
    await abrir(tester, const Size(360, 640));

    expect(find.text('0 productos'), findsOneWidget);
    expect(find.text('Todavía no hay productos en el surtido'), findsOneWidget);
  });

  testWidgets('si no carga avisa y deja intentar de nuevo', (tester) async {
    coordinador.fallaListar = StateError('disco');
    await abrir(tester, const Size(360, 640));

    expect(find.byType(TarjetaAviso), findsOneWidget);
    expect(find.text(ExistenciasViewModel.mensajeFalla), findsOneWidget);
    expect(find.text(SurtidoView.contexto), findsOneWidget);

    coordinador.fallaListar = null;
    await tester.ensureVisible(find.text('Intentar de nuevo'));
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();

    expect(find.byType(TarjetaAviso), findsNothing);
    expect(find.text('3 productos'), findsOneWidget);
  });

  for (final tamano in const [
    Size(320, 568),
    Size(360, 640),
    Size(800, 700),
    Size(1024, 768),
    Size(1280, 800),
  ]) {
    testWidgets(
      'sin desbordes en ${tamano.width.toInt()}×${tamano.height.toInt()} '
      'con el historial abierto',
      (tester) async {
        await abrir(tester, tamano);
        await tocarProducto(tester, 'Aceite 1 L');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
