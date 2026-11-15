import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/perdida_view.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Prueba de punta a punta de CUS-03: la vista con el módulo armado como en
/// `main.dart`, una base drift en memoria y las rutas de Surtido; el producto
/// se elige en Buscar producto (CUS-06) en modo seleccionar.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

  late BaseLocalDrift base;
  late CoordinadoresInventario inventario;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    inventario = registrarInventario(base, UnidadTrabajoDrift(base));
  });
  tearDown(() => base.close());

  Future<void> esperarBase(WidgetTester tester) async {
    // Las consultas de drift corren fuera del reloj falso de la prueba.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Crea el producto y le da [stock] con una entrada.
  Future<void> crear(
    WidgetTester tester,
    String nombre,
    UnidadMedida unidad,
    String stock,
  ) => tester.runAsync(() async {
    final Producto producto = await inventario.gestionarProducto.crearProducto(
      tienda,
      nombre.substring(0, 3).toUpperCase(),
      nombre,
      unidad,
      null,
      Decimal.parse('4200'),
    );
    await inventario.registrarEntradaMercancia.registrarEntrada(
      tienda,
      producto,
      Decimal.parse(stock),
      Decimal.parse('3000'),
      null,
    );
  });

  Future<void> abrirConProducto(
    WidgetTester tester,
    String buscar,
    String nombre, {
    Size tamano = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: rutaPrincipalSurtido,
      routes: [
        GoRoute(
          path: rutaPrincipalSurtido,
          builder: (_, _) => const SurtidoView(),
          routes: [
            GoRoute(
              path: 'buscar',
              builder: (_, state) => ChangeNotifierProvider(
                create: (_) =>
                    BuscarProductoViewModel(inventario.buscarProducto, tienda),
                child: BuscarProductoView(
                  modo: state.extra is ModoBusqueda
                      ? state.extra! as ModoBusqueda
                      : ModoBusqueda.editar,
                ),
              ),
            ),
            GoRoute(
              path: 'perdida',
              builder: (_, _) => ChangeNotifierProvider(
                create: (_) =>
                    PerdidaViewModel(inventario.registrarPerdida, tienda),
                child: const PerdidaView(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: TemaGip.claro(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('surtido_registrar_perdida')));
    await tester.pumpAndSettle();
    // En la web también sale en la miga.
    expect(find.text('Buscar producto'), findsWidgets);
    await tester.enterText(find.byKey(const Key('buscar_texto')), buscar);
    await esperarBase(tester);
    await tester.tap(find.text(nombre));
    await esperarBase(tester);
  }

  Future<void> escribirCantidad(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('perdida_cantidad')), texto);
    // El tendero cierra el teclado antes de bajar a los motivos.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> elegirMotivo(WidgetTester tester, String nombre) async {
    final opcion = find.byKey(Key('perdida_motivo_$nombre'));
    await tester.ensureVisible(opcion);
    // ensureVisible no redibuja: sin esto el toque usa la posición vieja.
    await tester.pumpAndSettle();
    await tester.tap(opcion);
    await tester.pumpAndSettle();
  }

  BotonPrimario boton(WidgetTester tester) =>
      tester.widget<BotonPrimario>(find.byKey(const Key('perdida_registrar')));

  Future<void> registrar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('perdida_registrar')));
    await tester.tap(find.byKey(const Key('perdida_registrar')));
    await esperarBase(tester);
  }

  Future<List<FilaMovimientoInventario>> mermas(WidgetTester tester) async =>
      (await tester.runAsync(
        () => (base.select(
          base.movimientosInventario,
        )..where((m) => m.tipo.equals('MERMA'))).get(),
      ))!;

  Future<Decimal> stockGuardado(WidgetTester tester) async =>
      (await tester.runAsync(
        () => base.select(base.itemsInventario).getSingle(),
      ))!.stockActual;

  testWidgets('registra la pérdida con su motivo desde Surtido', (
    tester,
  ) async {
    await crear(tester, 'Leche bolsa 1 L', UnidadMedida.unidad, '14');
    await abrirConProducto(tester, 'leche', 'Leche bolsa 1 L');

    expect(find.text('Pérdida o devolución'), findsOneWidget);
    expect(find.text('Hay 14'), findsOneWidget);
    expect(find.textContaining('· Unidad'), findsOneWidget);
    expect(find.text('Cambiar producto'), findsOneWidget);
    expect(find.text('¿CUÁNTAS SALEN DEL SURTIDO?'), findsOneWidget);
    expect(find.text('Producto y cantidad'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
    expect(find.text('Obligatorio'), findsOneWidget);
    expect(find.text('Pasó la fecha de vencimiento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('perdida_cantidad_mas')));
    await tester.tap(find.byKey(const Key('perdida_cantidad_mas')));
    await tester.pumpAndSettle();
    expect(find.text('12 unidades'), findsOneWidget);

    // Sin motivo no se puede confirmar (IE-03).
    expect(boton(tester).onPressed, isNull);
    await elegirMotivo(tester, 'vencido');
    expect(boton(tester).onPressed, isNotNull);
    // La nota va bajo los motivos (en el teléfono, al final de la lista).
    expect(find.textContaining('El motivo queda guardado'), findsOneWidget);

    await registrar(tester);

    expect(find.text('Pérdida registrada. Nuevo stock: 12'), findsOneWidget);
    expect(find.text('Hay 12'), findsOneWidget);
    expect(await stockGuardado(tester), Decimal.parse('12'));
    final fila = (await mermas(tester)).single;
    expect(fila.cantidad, Decimal.parse('-2'));
    expect(fila.motivo, 'VENCIDO');
    // Queda lista para otra: sin cantidad ni motivo.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('perdida_cantidad')))
          .controller!
          .text,
      isEmpty,
    );
    expect(boton(tester).onPressed, isNull);
  });

  testWidgets('cantidad mayor a la existencia: avisa y no guarda nada', (
    tester,
  ) async {
    await crear(tester, 'Leche bolsa 1 L', UnidadMedida.unidad, '14');
    await abrirConProducto(tester, 'leche', 'Leche bolsa 1 L');

    await escribirCantidad(tester, '15');
    expect(find.text('—'), findsOneWidget);
    await elegirMotivo(tester, 'danado');
    await registrar(tester);

    expect(find.text('La cantidad supera la existencia'), findsOneWidget);
    expect(await mermas(tester), isEmpty);
    expect(await stockGuardado(tester), Decimal.parse('14'));
  });

  testWidgets('cantidad cero muestra el mensaje del diagrama', (tester) async {
    await crear(tester, 'Leche bolsa 1 L', UnidadMedida.unidad, '14');
    await abrirConProducto(tester, 'leche', 'Leche bolsa 1 L');

    await escribirCantidad(tester, '0');
    await elegirMotivo(tester, 'otro');
    await registrar(tester);

    expect(
      find.text(
        'La cantidad debe ser mayor que cero y el motivo es obligatorio',
      ),
      findsOneWidget,
    );
    expect(await mermas(tester), isEmpty);
  });

  testWidgets('por kilo acepta decimales', (tester) async {
    await crear(tester, 'Queso costeño', UnidadMedida.kilogramo, '3');
    await abrirConProducto(tester, 'queso', 'Queso costeño');
    expect(find.text('Hay 3'), findsOneWidget);
    expect(find.textContaining('· Kilogramo'), findsOneWidget);

    await escribirCantidad(tester, '1,5');
    expect(find.text('1,5 kg'), findsOneWidget);
    await elegirMotivo(tester, 'devueltoProveedor');
    await registrar(tester);

    expect(find.text('Pérdida registrada. Nuevo stock: 1,5'), findsOneWidget);
    final fila = (await mermas(tester)).single;
    expect(fila.cantidad, Decimal.parse('-1.5'));
    expect(fila.motivo, 'DEVUELTO_PROVEEDOR');
  });

  testWidgets('"Todas (N)" saca toda la existencia', (tester) async {
    await crear(tester, 'Leche bolsa 1 L', UnidadMedida.unidad, '14');
    await abrirConProducto(tester, 'leche', 'Leche bolsa 1 L');

    await tester.ensureVisible(find.byKey(const Key('perdida_todas')));
    await tester.pumpAndSettle();
    expect(find.text('Todas (14)'), findsOneWidget);
    await tester.tap(find.text('Todas (14)'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('perdida_cantidad')))
          .controller!
          .text,
      '14',
    );
    expect(find.text('0 unidades'), findsOneWidget);

    await elegirMotivo(tester, 'vencido');
    await registrar(tester);
    expect(find.text('Pérdida registrada. Nuevo stock: 0'), findsOneWidget);
    // Sin existencia ya no hay atajo.
    expect(find.byKey(const Key('perdida_todas')), findsNothing);
  });

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('se ve completa en ${tamano.width.toInt()}x'
        '${tamano.height.toInt()} (RNF-19, RNF-20)', (tester) async {
      await crear(tester, 'Leche bolsa 1 L', UnidadMedida.unidad, '14');
      await abrirConProducto(
        tester,
        'leche',
        'Leche bolsa 1 L',
        tamano: tamano,
      );
      if (tamano.width >= 720) {
        expect(find.text('Registrar pérdida o devolución'), findsOneWidget);
        expect(find.text('Resumen'), findsOneWidget);
        expect(find.text('Hay ahora'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      }

      await escribirCantidad(tester, '2');
      await elegirMotivo(tester, 'devueltoProveedor');
      if (tamano.width >= 720) {
        expect(
          tester.widget<Text>(find.byKey(const Key('resumen_despues'))).data,
          '12',
        );
        expect(find.byKey(const Key('resumen_barra')), findsOneWidget);
        expect(find.text('− 2 und'), findsOneWidget);
      }
      await registrar(tester);
      expect(find.text('Pérdida registrada. Nuevo stock: 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
