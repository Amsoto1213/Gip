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
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Prueba de punta a punta de CUS-01: la vista con el módulo armado como en
/// `main.dart`, una base drift en memoria y las rutas de Surtido; el producto
/// se elige en Buscar producto (CUS-06) en modo seleccionar.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

  late BaseLocalDrift base;
  late CoordinadoresInventario inventario;
  late Producto aceite;

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

  Future<void> crearAceite(WidgetTester tester) => tester.runAsync(() async {
    aceite = await inventario.gestionarProducto.crearProducto(
      tienda,
      'ACE-1',
      'Aceite 1 L',
      UnidadMedida.unidad,
      null,
      Decimal.parse('11000'),
    );
  });

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    String inicio = rutaPrincipalSurtido,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: inicio,
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
              path: 'entrada',
              builder: (_, _) => ChangeNotifierProvider(
                create: (_) => EntradaMercanciaViewModel(
                  inventario.registrarEntradaMercancia,
                  tienda,
                ),
                child: const EntradaMercanciaView(),
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
  }

  /// Desde Surtido: "Registrar entrada" abre la búsqueda y se elige el aceite.
  Future<void> abrirEntradaConAceite(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
  }) async {
    await abrir(tester, tamano: tamano);
    await tester.tap(find.byKey(const Key('surtido_registrar_entrada')));
    await tester.pumpAndSettle();
    expect(find.text('Buscar producto'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('buscar_texto')), 'aceite');
    await esperarBase(tester);
    await tester.tap(find.text('Aceite 1 L'));
    await esperarBase(tester);
    expect(find.text('Entrada de mercancía'), findsOneWidget);
    // En la web el nombre sale también en el resumen.
    expect(find.text('Aceite 1 L'), findsWidgets);
  }

  Future<void> escribir(WidgetTester tester, String clave, String texto) async {
    await tester.enterText(find.byKey(Key(clave)), texto);
    await esperarBase(tester);
  }

  Future<void> registrar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('entrada_registrar')));
    await tester.tap(find.byKey(const Key('entrada_registrar')));
    await esperarBase(tester);
  }

  Future<Decimal> stockGuardado(WidgetTester tester) async {
    final fila = await tester.runAsync(
      () => base.select(base.itemsInventario).getSingle(),
    );
    return fila!.stockActual;
  }

  testWidgets('elige el producto en Buscar y registra la entrada', (
    tester,
  ) async {
    await crearAceite(tester);
    await abrirEntradaConAceite(tester);

    await escribir(tester, 'entrada_cantidad', '24');
    await escribir(tester, 'entrada_costo', '9.400');
    expect(find.text(r'$ 225.600'), findsOneWidget);
    // Sin entradas anteriores no hay advertencia.
    expect(find.byKey(const Key('entrada_advertencia_costo')), findsNothing);

    await escribir(tester, 'entrada_factura', 'FV-10231');
    await registrar(tester);

    expect(find.text('Entrada registrada. Nuevo stock: 24'), findsOneWidget);
    expect(await stockGuardado(tester), Decimal.parse('24'));
    final cantidad = tester.widget<TextField>(
      find.byKey(const Key('entrada_cantidad')),
    );
    expect(cantidad.controller!.text, isEmpty);
    final movimiento = await tester.runAsync(
      () => base.select(base.movimientosInventario).getSingle(),
    );
    expect(movimiento!.numeroFactura, 'FV-10231');
  });

  testWidgets('avisa si el costo cambió, pero deja registrar', (tester) async {
    await crearAceite(tester);
    await tester.runAsync(
      () => inventario.registrarEntradaMercancia.registrarEntrada(
        tienda,
        aceite,
        Decimal.parse('8'),
        Decimal.parse('8600'),
        null,
      ),
    );
    await abrirEntradaConAceite(tester);

    await escribir(tester, 'entrada_cantidad', '24');
    await escribir(tester, 'entrada_costo', '9400');
    expect(find.byKey(const Key('entrada_advertencia_costo')), findsOneWidget);
    expect(
      find.textContaining('El costo es distinto al de la última entrada'),
      findsOneWidget,
    );

    await escribir(tester, 'entrada_costo', '8.600');
    expect(find.byKey(const Key('entrada_advertencia_costo')), findsNothing);

    await escribir(tester, 'entrada_costo', '9400');
    await registrar(tester);
    expect(find.text('Entrada registrada. Nuevo stock: 32'), findsOneWidget);
    expect(find.byKey(const Key('entrada_advertencia_costo')), findsNothing);
  });

  testWidgets('los botones − y + cambian la cantidad', (tester) async {
    await crearAceite(tester);
    await abrirEntradaConAceite(tester);

    await tester.tap(find.byKey(const Key('entrada_cantidad_mas')));
    await tester.tap(find.byKey(const Key('entrada_cantidad_mas')));
    await tester.tap(find.byKey(const Key('entrada_cantidad_mas')));
    await tester.tap(find.byKey(const Key('entrada_cantidad_menos')));
    await tester.pumpAndSettle();

    final cantidad = tester.widget<TextField>(
      find.byKey(const Key('entrada_cantidad')),
    );
    expect(cantidad.controller!.text, '2');
  });

  testWidgets('cantidad cero muestra el mensaje del diagrama', (tester) async {
    await crearAceite(tester);
    await abrirEntradaConAceite(tester);

    await escribir(tester, 'entrada_cantidad', '0');
    await escribir(tester, 'entrada_costo', '9400');
    await registrar(tester);

    expect(
      find.text(
        'La cantidad debe ser mayor que cero y el costo no puede ser negativo',
      ),
      findsOneWidget,
    );
    expect(await stockGuardado(tester), Decimal.zero);
  });

  testWidgets('si vuelve de Buscar sin elegir, puede elegir después', (
    tester,
  ) async {
    await crearAceite(tester);
    await abrir(tester, inicio: rutaEntradaMercancia);
    expect(find.text('Buscar producto'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Entrada de mercancía'), findsOneWidget);
    expect(find.text('¿Qué producto llegó?'), findsOneWidget);

    await registrar(tester);
    expect(find.text('Elija el producto que llegó'), findsOneWidget);

    await tester.tap(find.byKey(const Key('entrada_elegir_producto')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('buscar_texto')), 'aceite');
    await esperarBase(tester);
    await tester.tap(find.text('Aceite 1 L'));
    await esperarBase(tester);
    expect(find.text('Aceite 1 L'), findsOneWidget);
    expect(find.text('Cambiar producto'), findsOneWidget);
  });

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('se ve completa en ${tamano.width.toInt()}x'
        '${tamano.height.toInt()} (RNF-19, RNF-20)', (tester) async {
      await crearAceite(tester);
      await tester.runAsync(
        () => inventario.registrarEntradaMercancia.registrarEntrada(
          tienda,
          aceite,
          Decimal.one,
          Decimal.parse('8600'),
          null,
        ),
      );
      await abrirEntradaConAceite(tester, tamano: tamano);

      await escribir(tester, 'entrada_cantidad', '24');
      await escribir(tester, 'entrada_costo', '9400');
      expect(
        find.byKey(const Key('entrada_advertencia_costo')),
        findsOneWidget,
      );
      expect(find.text(r'$ 225.600'), findsOneWidget);
      if (tamano.width >= 720) {
        expect(find.text('Registrar entrada de mercancía'), findsOneWidget);
        expect(find.text('Costo y factura'), findsOneWidget);
        expect(find.text('Total de la compra'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        // En una entrada el surtido sube: sin barra de lo que se quita.
        expect(find.byKey(const Key('resumen_barra')), findsNothing);
      }
      await registrar(tester);
      expect(find.text('Entrada registrada. Nuevo stock: 25'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
