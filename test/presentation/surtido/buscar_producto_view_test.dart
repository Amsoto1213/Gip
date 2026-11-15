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
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Prueba de punta a punta de CUS-06 (por nombre): la vista con el módulo
/// armado como en `main.dart`, una base drift en memoria y las mismas rutas de
/// Surtido.
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

  Future<void> crear(String codigo, String nombre, String precio) =>
      inventario.gestionarProducto.crearProducto(
        tienda,
        codigo,
        nombre,
        UnidadMedida.unidad,
        null,
        Decimal.parse(precio),
      );

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    String seccion = 'Surtido',
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: rutaBuscarProducto,
      routes: [
        GoRoute(
          path: rutaPrincipalSurtido,
          builder: (_, _) => const SizedBox(),
          routes: [
            GoRoute(
              path: 'buscar',
              builder: (_, _) => ChangeNotifierProvider(
                create: (_) =>
                    BuscarProductoViewModel(inventario.buscarProducto, tienda),
                child: BuscarProductoView(seccion: seccion),
              ),
            ),
            GoRoute(
              path: 'producto',
              builder: (_, state) => ChangeNotifierProvider(
                create: (_) => ProductoViewModel(
                  inventario.gestionarProducto,
                  tienda,
                  producto: state.extra as Producto?,
                ),
                child: const ProductoView(),
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

  Future<void> escribir(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('buscar_texto')), texto);
    await esperarBase(tester);
  }

  testWidgets('filtra en tiempo real sin tildes ni mayúsculas', (tester) async {
    await tester.runAsync(() async {
      await crear('AZU', 'Azúcar Manuelita', '4200');
      await crear('ARR', 'ARROZ Diana', '2800');
    });
    await abrir(tester);
    expect(find.textContaining('Escriba el nombre'), findsOneWidget);

    await escribir(tester, 'AZUCAR');
    expect(find.text('Azúcar Manuelita'), findsOneWidget);
    expect(find.text('ARROZ Diana'), findsNothing);
    expect(find.text(r'$ 4.200'), findsOneWidget);
    expect(find.textContaining('1 resultado'), findsOneWidget);

    await escribir(tester, 'a');
    expect(find.text('Azúcar Manuelita'), findsOneWidget);
    expect(find.text('ARROZ Diana'), findsOneWidget);
  });

  testWidgets(
    'al seleccionar abre el producto para editarlo y al volver muestra el '
    'cambio',
    (tester) async {
      await tester.runAsync(() => crear('COCO', 'Coco', '3000'));
      await abrir(tester);
      await escribir(tester, 'coco');

      await tester.tap(find.text('Coco'));
      await tester.pumpAndSettle();
      expect(find.text('Editar producto'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'COCO'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('producto_nombre')),
        'Coco grande',
      );
      // El botón va al final de la lista: baja hasta él y vuelve a subir.
      final lista = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Guardar producto'),
        200,
        scrollable: lista,
      );
      await tester.tap(find.text('Guardar producto'));
      await esperarBase(tester);
      expect(find.text('Producto actualizado'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byTooltip('Volver'),
        -200,
        scrollable: lista,
      );
      await tester.tap(find.byTooltip('Volver'));
      await esperarBase(tester);
      // En la web también sale en la miga.
      expect(find.text('Buscar producto'), findsWidgets);
      expect(find.text('Coco grande'), findsOneWidget);
    },
  );

  testWidgets('sin coincidencias ofrece crear el producto', (tester) async {
    await abrir(tester);

    await escribir(tester, 'leche');

    expect(
      find.text('No se encontró el producto. ¿Desea crearlo?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('buscar_crear_sin_coincidencias')));
    await tester.pumpAndSettle();
    expect(find.text('Producto nuevo'), findsOneWidget);
  });

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('se ve completa en ${tamano.width.toInt()}x'
        '${tamano.height.toInt()} (RNF-19, RNF-20)', (tester) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 12; i++) {
          await crear('C$i', 'Galletas de coco número $i', '3500');
        }
      });
      await abrir(tester, tamano: tamano);

      await escribir(tester, 'galletas');
      expect(find.textContaining('12 resultados'), findsOneWidget);
      await escribir(tester, 'leche');
      expect(
        find.text('No se encontró el producto. ¿Desea crearlo?'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('en la web la miga lleva a la sección que la abrió', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(1280, 800), seccion: 'Vender');
    expect(find.byTooltip('Volver a Vender'), findsOneWidget);
    expect(find.text('Vender'), findsOneWidget);
    expect(find.text('¿No lo encuentra?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
