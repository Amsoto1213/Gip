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
import 'package:gip/presentation/surtido/conteo_view.dart';
import 'package:gip/presentation/surtido/conteo_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Prueba de punta a punta de CUS-04: la vista con el módulo armado como en
/// `main.dart`, una base drift en memoria y la ruta desde Surtido.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

  late BaseLocalDrift base;
  late CoordinadoresInventario inventario;
  final productos = <String, Producto>{};

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    inventario = registrarInventario(base, UnidadTrabajoDrift(base));
    productos.clear();
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
    String codigo,
    String nombre,
    String stock, [
    UnidadMedida unidad = UnidadMedida.unidad,
  ]) => tester.runAsync(() async {
    final producto = await inventario.gestionarProducto.crearProducto(
      tienda,
      codigo,
      nombre,
      unidad,
      null,
      Decimal.parse('4200'),
    );
    productos[nombre] = producto;
    await inventario.registrarEntradaMercancia.registrarEntrada(
      tienda,
      producto,
      Decimal.parse(stock),
      Decimal.parse('3000'),
      null,
    );
  });

  Future<Decimal> stock(WidgetTester tester, String nombre) async =>
      (await tester.runAsync(
        () => inventario.registrarPerdida.consultarExistencia(
          tienda,
          productos[nombre]!,
        ),
      ))!;

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await crear(tester, 'ARR-1', 'Arroz 500 g', '46');
    await crear(tester, 'CAF-1', 'Café molido 250 g', '21');
    await crear(tester, 'HUE-1', 'Huevo AA', '90');
    await crear(tester, 'QUE-1', 'Queso costeño', '3', UnidadMedida.kilogramo);
    final router = GoRouter(
      initialLocation: rutaPrincipalSurtido,
      routes: [
        GoRoute(
          path: rutaPrincipalSurtido,
          builder: (_, _) => const SurtidoView(),
          routes: [
            GoRoute(
              path: 'conteo',
              builder: (_, _) => ChangeNotifierProvider(
                create: (_) =>
                    ConteoViewModel(inventario.registrarConteo, tienda)
                      ..cargar(),
                child: const ConteoView(),
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
    await tester.tap(find.byKey(const Key('surtido_conteo')));
    await esperarBase(tester);
  }

  Finder campo(String nombre) =>
      find.byKey(Key('conteo_contado_${productos[nombre]!.getId()}'));

  Finder diferencia(String nombre) =>
      find.byKey(Key('conteo_diferencia_${productos[nombre]!.getId()}'));

  Future<void> contar(WidgetTester tester, String nombre, String texto) async {
    // La lista solo construye lo visible: se desplaza hasta el campo.
    await tester.scrollUntilVisible(
      campo(nombre),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(campo(nombre), texto);
    await esperarBase(tester);
  }

  String textoDe(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

  /// Scrollable de la lista de la pantalla (los campos tienen el suyo).
  Finder lista() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  /// Vuelve al principio de la pantalla: la lista solo construye lo visible.
  Future<void> irArriba(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
  }

  Future<void> confirmar(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final boton = find.byKey(const Key('conteo_confirmar'));
    await tester.scrollUntilVisible(boton, 300, scrollable: lista());
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await esperarBase(tester);
    await esperarBase(tester);
  }

  testWidgets('móvil 360×640: lista, diferencia, aviso y ajuste guardado', (
    tester,
  ) async {
    await abrir(tester, const Size(360, 640));

    expect(find.text('Conteo físico'), findsOneWidget);
    expect(find.text('0 de 4 contados'), findsOneWidget);
    expect(find.text('Según el sistema: 90'), findsOneWidget);
    // Sin lector ni "Pausar" (DI-24).
    expect(find.byTooltip('Leer código con el lector'), findsNothing);
    expect(find.textContaining('Pausar'), findsNothing);

    await contar(tester, 'Café molido 250 g', '23');
    expect(textoDe(tester, diferencia('Café molido 250 g')), '+2');
    expect(find.byKey(const Key('conteo_aviso_revisar')), findsNothing);

    await contar(tester, 'Huevo AA', '78');
    expect(textoDe(tester, diferencia('Huevo AA')), '−12');
    expect(find.text(ConteoViewModel.mensajeRevisar), findsWidgets);
    await irArriba(tester);
    expect(find.text('1 diferencia grande'), findsOneWidget);
    expect(find.text('2 de 4 contados'), findsOneWidget);
    expect(find.text('Confirmar ajuste de 2 productos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Volver a contar borra la cantidad del huevo.
    final volver = find.byKey(
      Key('conteo_volver_${productos['Huevo AA']!.getId()}'),
    );
    await tester.ensureVisible(volver);
    await tester.pumpAndSettle();
    await tester.tap(volver);
    await esperarBase(tester);
    expect(find.text(ConteoViewModel.mensajeRevisar), findsNothing);
    await irArriba(tester);
    expect(find.text('1 de 4 contados'), findsOneWidget);

    await confirmar(tester);
    expect(find.text('Ajuste registrado. Nuevo stock: 23'), findsOneWidget);
    expect(await stock(tester, 'Café molido 250 g'), Decimal.fromInt(23));
    expect(await stock(tester, 'Huevo AA'), Decimal.fromInt(90));
    await irArriba(tester);
    expect(find.text('0 de 4 contados'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Según el sistema: 23'),
      200,
      scrollable: lista(),
    );
    expect(find.text('Según el sistema: 23'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('móvil: por unidad no acepta decimales; por kilo sí', (
    tester,
  ) async {
    await abrir(tester, const Size(360, 640));

    await contar(tester, 'Arroz 500 g', '2,5');
    expect(find.text(ConteoViewModel.mensajeSoloEnteros), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('conteo_confirmar')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await contar(tester, 'Arroz 500 g', '');
    await contar(tester, 'Queso costeño', '2,5');
    expect(textoDe(tester, diferencia('Queso costeño')), '−0,5');
    await confirmar(tester);
    expect(await stock(tester, 'Queso costeño'), Decimal.parse('2.5'));
  });

  testWidgets('cantidad negativa: el mensaje del servicio y no se guarda', (
    tester,
  ) async {
    await abrir(tester, const Size(360, 640));

    await contar(tester, 'Huevo AA', '-1');
    await confirmar(tester);
    expect(
      find.text('La cantidad contada no puede ser negativa'),
      findsOneWidget,
    );
    expect(await stock(tester, 'Huevo AA'), Decimal.fromInt(90));
  });

  testWidgets('web 1280×800: tabla, filtro por nombre y ajuste de varios', (
    tester,
  ) async {
    await abrir(tester, const Size(1280, 800));

    for (final columna in [
      'Producto',
      'Código',
      'Según el sistema',
      'Contado',
      'Diferencia',
      'Estado',
    ]) {
      expect(find.text(columna), findsOneWidget);
    }
    expect(find.text('HUE-1'), findsOneWidget);

    await contar(tester, 'Arroz 500 g', '46');
    expect(find.text('Cuadra'), findsOneWidget);
    await contar(tester, 'Café molido 250 g', '20');
    expect(find.text('Se ajusta'), findsOneWidget);
    await contar(tester, 'Huevo AA', '78');
    expect(find.text('Volver a contar'), findsOneWidget);
    await irArriba(tester);
    expect(find.text('1 diferencia grande'), findsOneWidget);

    // Filtro por nombre sin tilde (como Buscar producto).
    await tester.enterText(find.byKey(const Key('conteo_buscar')), 'cafe');
    await tester.pumpAndSettle();
    expect(find.text('Café molido 250 g'), findsOneWidget);
    expect(find.text('Huevo AA'), findsNothing);
    await tester.enterText(find.byKey(const Key('conteo_buscar')), '');
    await tester.pumpAndSettle();

    // Con diferencia: café y huevo.
    await tester.tap(find.text('Con diferencia · 2'));
    await tester.pumpAndSettle();
    expect(find.text('Arroz 500 g'), findsNothing);
    expect(find.text('Huevo AA'), findsOneWidget);
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // El aviso no bloquea: se confirman los tres, incluido el que cuadra.
    await confirmar(tester);
    expect(find.text('Ajuste registrado en 3 productos'), findsOneWidget);
    expect(await stock(tester, 'Arroz 500 g'), Decimal.fromInt(46));
    expect(await stock(tester, 'Café molido 250 g'), Decimal.fromInt(20));
    expect(await stock(tester, 'Huevo AA'), Decimal.fromInt(78));
    expect(await stock(tester, 'Queso costeño'), Decimal.fromInt(3));
    expect(tester.takeException(), isNull);
  });

  for (final tamano in const [Size(320, 568), Size(800, 700)]) {
    testWidgets('sin desbordes en ${tamano.width.toInt()}×'
        '${tamano.height.toInt()} con una diferencia grande', (tester) async {
      await abrir(tester, tamano);
      await contar(tester, 'Huevo AA', '78');
      await irArriba(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
