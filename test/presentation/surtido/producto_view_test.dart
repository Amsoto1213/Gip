import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:provider/provider.dart';

class ImpresionGrabadora implements IImpresionEtiquetas {
  final List<List<Etiqueta>> envios = [];

  @override
  Future<void> imprimir(List<Etiqueta> etiquetas) async =>
      envios.add(etiquetas);
}

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

  /// El botón va al final de la lista: baja hasta él. `scrollUntilVisible` se
  /// detiene en cuanto la lista lo construye, aunque quede fuera de la
  /// pantalla; `ensureVisible` lo trae a la vista para poder tocarlo.
  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) async {
    await tester.scrollUntilVisible(
      objetivo,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
  }

  /// Sube hasta [objetivo] (el título o los primeros campos).
  Future<void> subirHasta(WidgetTester tester, Finder objetivo) =>
      tester.scrollUntilVisible(
        objetivo,
        -200,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> guardar(WidgetTester tester) async {
    // Sin foco, el campo editado no vuelve a subir la lista al cursor.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
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
    await subirHasta(tester, find.text('Editar producto'));
    expect(find.text('Editar producto'), findsOneWidget);

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
    await subirHasta(tester, find.text('Producto nuevo'));
    expect(find.text('Producto nuevo'), findsOneWidget);
  });

  testWidgets('en escritorio muestra Cancelar y los precios en una fila', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(1280, 900));
    final venta = tester.getTopLeft(
      find.byKey(const Key('producto_precio_venta')),
    );
    final costo = tester.getTopLeft(
      find.byKey(const Key('producto_precio_compra')),
    );
    expect(venta.dy, costo.dy);
    await bajarHasta(tester, find.text('Cancelar'));
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('asocia un código al producto nuevo al crearlo (CUS-17)', (
    tester,
  ) async {
    await abrir(tester);
    await escribir(tester, 'codigo', 'LEC-1');
    await escribir(tester, 'nombre', 'Leche bolsa 1 L');
    await escribir(tester, 'precio_venta', '4.200');

    await bajarHasta(tester, find.text('Asociar código'));
    await tester.tap(find.text('Asociar código'));
    await tester.pumpAndSettle();
    // El lector 2D en modo teclado escribe en el campo del diálogo.
    await tester.enterText(
      find.byKey(const Key('producto_valor_codigo')),
      '7701234567897',
    );
    await tester.tap(find.byKey(const Key('producto_confirmar_codigo')));
    await tester.pumpAndSettle();
    expect(find.text('Se asociará al guardar el producto'), findsOneWidget);
    expect(find.text('Asociar otro código'), findsOneWidget);

    await guardar(tester);

    expect(find.text('Producto creado. Código asociado'), findsOneWidget);
    expect(find.text('EAN-13'), findsOneWidget);
    final leido = await tester.runAsync(
      () =>
          ProductoRepositorioDrift(base)
              .buscarPorCodigoProducto(tienda, '7701234567897'),
    );
    expect(leido!.getNombre(), 'Leche bolsa 1 L');
  });

  testWidgets('el código pendiente se puede descartar', (tester) async {
    await abrir(tester);
    await bajarHasta(tester, find.text('Asociar código'));
    await tester.tap(find.text('Asociar código'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('producto_valor_codigo')),
      'GIP:LEC-1',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('GIP:LEC-1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('producto_descartar_codigo')));
    await tester.pumpAndSettle();

    expect(find.text('GIP:LEC-1'), findsNothing);
    expect(find.text('Asociar código'), findsOneWidget);
  });

  testWidgets('un código repetido muestra el mensaje del diagrama', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final otro = await coordinator.crearProducto(
        tienda,
        'ARR-1',
        'Arroz',
        UnidadMedida.libra,
        null,
        Decimal.parse('2800'),
      );
      await coordinator.asociarCodigo(tienda, otro, '7701234567897');
    });
    await abrir(tester);
    await escribir(tester, 'codigo', 'LEC-1');
    await escribir(tester, 'nombre', 'Leche');
    await escribir(tester, 'precio_venta', '4.200');
    await bajarHasta(tester, find.text('Asociar código'));
    await tester.tap(find.text('Asociar código'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('producto_valor_codigo')),
      '7701234567897',
    );
    await tester.tap(find.byKey(const Key('producto_confirmar_codigo')));
    await tester.pumpAndSettle();

    await guardar(tester);

    // El producto queda creado; el código no. Los dos mensajes empujan la
    // lista hacia abajo.
    await tester.ensureVisible(
      find.text('Producto creado', skipOffstage: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Producto creado'), findsOneWidget);
    expect(
      find.text('Ese código ya está asociado a otro producto'),
      findsOneWidget,
    );
  });

  testWidgets('el costo dice que lo actualiza la entrada (DI-33)', (
    tester,
  ) async {
    await abrir(tester);
    expect(
      find.text('Cada entrada de mercancía lo actualiza con su costo.'),
      findsOneWidget,
    );
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

  group('etiquetas', () {
    late ImpresionGrabadora impresion;
    late Producto galletas;

    /// Como `main.dart`, pero con una impresión falsa: la real abriría el
    /// diálogo de impresión del sistema.
    Future<void> abrirConProducto(
      WidgetTester tester, {
      Size tamano = const Size(390, 844),
    }) async {
      impresion = ImpresionGrabadora();
      final productos = ProductoRepositorioDrift(base);
      final unidad = UnidadTrabajoDrift(base);
      final servicio = ServicioCatalogo(
        productos,
        const [],
        ServicioInventario(
          InventarioRepositorioDrift(base),
          MovimientoInventarioRepositorioDrift(base),
          Decimal.one,
          unidad,
          productos,
        ),
        impresion,
        unidad,
      );
      galletas = await tester.runAsync(
        () => servicio.crearProducto(
          tienda,
          'GAL-6',
          'Galletas de coco x 6',
          UnidadMedida.unidad,
          Decimal.parse('2600'),
          Decimal.parse('3500'),
        ),
      ) as Producto;
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaGip.claro(),
          home: ChangeNotifierProvider(
            create: (_) => ProductoViewModel(
              GestionarProductoCoordinator(servicio),
              tienda,
              producto: galletas,
            ),
            child: const ProductoView(),
          ),
        ),
      );
    }

    testWidgets('un producto nuevo no muestra el panel', (tester) async {
      await abrir(tester);
      expect(find.byKey(const Key('producto_panel_etiquetas')), findsNothing);
    });

    testWidgets('imprime las copias elegidas y avisa (móvil)', (tester) async {
      await abrirConProducto(tester);
      await bajarHasta(tester, find.text('Imprimir etiquetas'));
      expect(find.text('Etiquetas QR'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('contador_menos')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('contador_menos')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('producto_imprimir_etiquetas')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Etiquetas enviadas a impresión'), findsOneWidget);
      final etiquetas = impresion.envios.single;
      expect(etiquetas, hasLength(8));
      final codigo = etiquetas.first.getCodigo();
      expect(codigo.getFormato(), FormatoCodigo.qr);
      expect(codigo.getValor(), 'GIP:GAL-6');
    });

    testWidgets('en escritorio el panel va al lado del formulario', (
      tester,
    ) async {
      await abrirConProducto(tester, tamano: const Size(1280, 800));

      final panel = tester.getRect(
        find.byKey(const Key('producto_panel_etiquetas')),
      );
      final datos = tester.getRect(find.byKey(const Key('producto_nombre')));
      expect(panel.left, greaterThan(datos.right));
      expect(panel.top, lessThan(datos.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin desbordes en 360×640 y con áreas de 44 px', (
      tester,
    ) async {
      await abrirConProducto(tester, tamano: const Size(360, 640));
      await bajarHasta(tester, find.text('Imprimir etiquetas'));

      for (final clave in ['contador_menos', 'contador_mas']) {
        expect(
          tester.getSize(find.byKey(Key(clave))).shortestSide,
          greaterThanOrEqualTo(44),
        );
      }
      expect(
        tester
            .getSize(find.byKey(const Key('producto_imprimir_etiquetas')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
