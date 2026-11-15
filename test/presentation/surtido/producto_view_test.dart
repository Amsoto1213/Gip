import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:provider/provider.dart';

/// Prueba de punta a punta de CUS-18: la vista con el módulo armado como en
/// `main.dart` y una base drift en memoria.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

  late BaseLocalDrift base;
  late GestionarProductoCoordinator coordinator;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    coordinator = registrarInventario(
      base,
      UnidadTrabajoDrift(base),
    ).gestionarProducto;
  });
  tearDown(() => base.close());

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => ProductoViewModel(coordinator, tienda),
          child: const ProductoView(),
        ),
      ),
    );
  }

  Future<void> escribir(WidgetTester tester, String campo, String texto) =>
      tester.enterText(find.byKey(Key('producto_$campo')), texto);

  /// El botón va al final de la lista: baja hasta él.
  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) =>
      tester.scrollUntilVisible(
        objetivo,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> guardar(WidgetTester tester) async {
    await bajarHasta(tester, find.text('Guardar producto'));
    await tester.tap(find.text('Guardar producto'));
    // Las consultas de drift corren fuera del reloj falso de la prueba.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('crea el producto con su ítem en cero y pasa a editar', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Producto nuevo'), findsOneWidget);

    await escribir(tester, 'codigo', 'GAL-6');
    await escribir(tester, 'nombre', 'Galletas de coco x 6');
    await tester.tap(find.text('Kilo'));
    await escribir(tester, 'precio_venta', '3.500');
    await escribir(tester, 'precio_compra', '2.600');
    await guardar(tester);

    expect(find.text('Producto creado'), findsOneWidget);
    // El título quedó arriba, fuera de la vista tras bajar al botón.
    expect(find.text('Editar producto', skipOffstage: false), findsOneWidget);

    final lista = await tester.runAsync(
      () => InventarioRepositorioDrift(base).listarItems(tienda),
    );
    final item = lista!.single;
    expect(item.getStockActual(), Decimal.zero);
    expect(item.getProducto().getNombre(), 'Galletas de coco x 6');
    expect(item.getProducto().getPrecioCompra(), Decimal.parse('2600'));

    // El código interno queda bloqueado al editar (DI-14).
    final codigo = tester.widget<TextField>(
      find.byKey(const Key('producto_codigo')),
    );
    expect(codigo.enabled, isFalse);

    await escribir(tester, 'nombre', 'Galletas de coco x 12');
    await escribir(tester, 'precio_venta', '6.800');
    await guardar(tester);

    expect(find.text('Producto actualizado'), findsOneWidget);
    final editado = await tester.runAsync(
      () => ProductoRepositorioDrift(base).buscarPorCodigo(tienda, 'GAL-6'),
    );
    expect(editado!.getNombre(), 'Galletas de coco x 12');
    expect(editado.getPrecioVenta(), Decimal.parse('6800'));
  });

  testWidgets('muestra el mensaje del diagrama si faltan datos', (
    tester,
  ) async {
    await abrir(tester);

    await escribir(tester, 'codigo', 'GAL-6');
    await escribir(tester, 'precio_venta', '3.500');
    await guardar(tester);

    expect(
      find.text('El código interno ya existe o faltan datos válidos'),
      findsOneWidget,
    );
    expect(find.text('Producto nuevo', skipOffstage: false), findsOneWidget);
  });

  testWidgets('en escritorio muestra Cancelar y los precios en una fila', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(1280, 900));
    expect(find.text('Cancelar'), findsOneWidget);
    final venta = tester.getTopLeft(
      find.byKey(const Key('producto_precio_venta')),
    );
    final costo = tester.getTopLeft(
      find.byKey(const Key('producto_precio_compra')),
    );
    expect(venta.dy, costo.dy);
  });

  testWidgets('las áreas táctiles miden al menos 44 px (RNF-19)', (
    tester,
  ) async {
    await abrir(tester);
    await bajarHasta(tester, find.text('Guardar producto'));
    for (final texto in ['Unidad', 'Kilo', 'Libra', 'Guardar producto']) {
      final caja = tester.getSize(
        find
            .ancestor(of: find.text(texto), matching: find.byType(InkWell))
            .first,
      );
      expect(caja.height, greaterThanOrEqualTo(44), reason: texto);
    }
  });
}
