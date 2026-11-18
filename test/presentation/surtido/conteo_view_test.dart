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
import 'package:gip/presentation/surtido/existencias_view_model.dart';
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
          builder: (_, _) => ChangeNotifierProvider(
            create: (_) =>
                ExistenciasViewModel(inventario.consultarExistencias, tienda)
                  ..cargar(),
            child: const SurtidoView(),
          ),
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
    // La lista de existencias carga de drift (CUS-25).
    await esperarBase(tester);
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

  /// Color de fondo de la fila de [nombre].
  Color? fondoFila(WidgetTester tester, String nombre) => tester
      .widget<Container>(
        find.byKey(Key('conteo_fila_${productos[nombre]!.getId()}')),
      )
      .color;

  /// Scrollable de la lista de la pantalla (los campos tienen el suyo).
  Finder lista() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  /// Vuelve al principio de la pantalla: la lista solo construye lo visible.
  Future<void> irArriba(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
  }

  /// El botón de confirmar; en la web está al final de la lista.
  Future<FilledButton> botonConfirmar(WidgetTester tester) async {
    final boton = find.byKey(const Key('conteo_confirmar'));
    await tester.scrollUntilVisible(boton, 300, scrollable: lista());
    await tester.pumpAndSettle();
    return tester.widget<FilledButton>(
      find.descendant(of: boton, matching: find.byType(FilledButton)),
    );
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
    expect(find.text('Según el sistema: 3 kg'), findsOneWidget);
    // Filtros del prototipo móvil.
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Sin contar · 4'), findsOneWidget);
    expect(find.text('Diferencia · 0'), findsOneWidget);
    // Sin lector, "Pausar" ni "Volver a contar" (DI-24).
    expect(find.byTooltip('Leer código con la cámara'), findsNothing);
    expect(find.textContaining('Pausar'), findsNothing);
    expect(find.text('Volver a contar'), findsNothing);
    expect(find.textContaining('cada producto contado'), findsNothing);

    await contar(tester, 'Café molido 250 g', '23');
    expect(textoDe(tester, diferencia('Café molido 250 g')), '+2');
    expect(find.byKey(const Key('conteo_aviso_revisar')), findsNothing);

    await contar(tester, 'Huevo AA', '78');
    expect(textoDe(tester, diferencia('Huevo AA')), '−12');
    // Diferencia grande en rojo con el mensaje del diagrama (no amarillo).
    final revisar = find.text(ConteoViewModel.mensajeRevisar);
    expect(revisar, findsOneWidget);
    expect(tester.widget<Text>(revisar).style?.color, ColoresGip.error);
    expect(
      tester.widget<Text>(diferencia('Huevo AA')).style?.color,
      ColoresGip.error,
    );
    expect(fondoFila(tester, 'Huevo AA'), ColoresGip.errorFondoSuave);
    expect(fondoFila(tester, 'Café molido 250 g'), ColoresGip.superficie);
    await irArriba(tester);
    final porRevisar = find.text('1 por revisar');
    expect(porRevisar, findsOneWidget);
    expect(tester.widget<Text>(porRevisar).style?.color, ColoresGip.error);
    expect(find.text('2 de 4 contados'), findsOneWidget);
    expect(find.text('Confirmar ajuste de 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // El número se corrige en el mismo campo: al borrarlo queda sin contar.
    await contar(tester, 'Huevo AA', '');
    expect(find.text(ConteoViewModel.mensajeRevisar), findsNothing);
    expect(textoDe(tester, diferencia('Huevo AA')), '—');
    await irArriba(tester);
    expect(find.text('1 de 4 contados'), findsOneWidget);
    expect(find.text('1 por revisar'), findsNothing);

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

  for (final tamano in const [Size(360, 640), Size(1280, 800)]) {
    testWidgets('${tamano.width.toInt()}×${tamano.height.toInt()}: cantidad '
        'negativa en rojo al escribir, sin diferencia ni aviso y sin '
        'confirmar', (tester) async {
      await abrir(tester, tamano);

      await contar(tester, 'Arroz 500 g', '45');
      await contar(tester, 'Huevo AA', '-1');
      final mensaje = find.text('La cantidad contada no puede ser negativa');
      expect(mensaje, findsOneWidget);
      expect(tester.widget<Text>(mensaje).style?.color, ColoresGip.error);
      expect(textoDe(tester, diferencia('Huevo AA')), '—');
      expect(fondoFila(tester, 'Huevo AA'), ColoresGip.errorFondoSuave);
      expect(find.text(ConteoViewModel.mensajeRevisar), findsNothing);
      await irArriba(tester);
      expect(find.byKey(const Key('conteo_aviso_revisar')), findsNothing);
      expect(find.text('1 de 4 contados'), findsOneWidget);
      expect((await botonConfirmar(tester)).onPressed, isNull);

      // Se corrige en el mismo campo y se puede confirmar.
      await contar(tester, 'Huevo AA', '88');
      expect(mensaje, findsNothing);
      expect((await botonConfirmar(tester)).onPressed, isNotNull);
      expect(await stock(tester, 'Huevo AA'), Decimal.fromInt(90));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('web 1280×800: tabla, filtro por nombre y ajuste de varios', (
    tester,
  ) async {
    await abrir(tester, const Size(1280, 800));

    for (final columna in [
      'PRODUCTO',
      'SEGÚN EL SISTEMA',
      'CONTADO',
      'DIFERENCIA',
      'ESTADO',
    ]) {
      expect(find.text(columna), findsOneWidget);
    }
    expect(find.text('Avance del conteo'), findsOneWidget);
    expect(find.text('0 de 4 contados'), findsOneWidget);
    expect(find.text('Kilogramo'), findsOneWidget);
    expect(find.text('Sin contar'), findsNWidgets(4));
    expect(find.text('Todos · 4'), findsOneWidget);
    expect(find.text('Contados · 0'), findsOneWidget);
    expect(find.text('Sin contar · 4'), findsOneWidget);
    expect(find.text('Con diferencia · 0'), findsOneWidget);
    expect(find.text('Volver a contar'), findsNothing);
    expect(find.textContaining('Pausar'), findsNothing);
    expect(find.byKey(const Key('conteo_aviso_revisar')), findsNothing);

    await contar(tester, 'Arroz 500 g', '46');
    expect(find.text('Cuadra'), findsOneWidget);
    await contar(tester, 'Café molido 250 g', '20');
    expect(find.text('Se ajusta'), findsOneWidget);
    await contar(tester, 'Huevo AA', '78');
    expect(find.text('Diferencia grande'), findsOneWidget);
    expect(fondoFila(tester, 'Huevo AA'), ColoresGip.errorFondoSuave);
    expect(find.text('Sin contar'), findsOneWidget);
    await irArriba(tester);
    // Tarjeta roja, sin el número del umbral.
    final aviso = find.byKey(const Key('conteo_aviso_revisar'));
    expect(
      find.descendant(of: aviso, matching: find.text('1 diferencia grande')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: aviso,
        matching: find.text(ConteoViewModel.mensajeRevisar),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('5 unidades'), findsNothing);
    expect(
      tester.widget<Text>(find.text('1 diferencia grande')).style?.color,
      ColoresGip.errorTexto,
    );
    expect(find.text('3 de 4 contados'), findsOneWidget);

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
    await tester.tap(find.text('Todos · 4'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Abajo, solo el botón.
    await botonConfirmar(tester);
    expect(find.text('Confirmar ajuste de 3 productos'), findsOneWidget);
    expect(find.textContaining('cada producto contado'), findsNothing);

    // El aviso no bloquea: se confirman los tres, incluido el que cuadra.
    await confirmar(tester);
    expect(find.text('Ajuste registrado en 3 productos'), findsOneWidget);
    expect(await stock(tester, 'Arroz 500 g'), Decimal.fromInt(46));
    expect(await stock(tester, 'Café molido 250 g'), Decimal.fromInt(20));
    expect(await stock(tester, 'Huevo AA'), Decimal.fromInt(78));
    expect(await stock(tester, 'Queso costeño'), Decimal.fromInt(3));
    expect(tester.takeException(), isNull);
  });

  /// Escribe [digitos] uno por uno en el campo que tiene el foco, como el
  /// teclado: cada tecla cambia el texto y deja correr la consulta de la
  /// diferencia antes de la siguiente.
  Future<void> teclear(WidgetTester tester, String digitos) async {
    var texto = '';
    for (final digito in digitos.split('')) {
      texto += digito;
      tester.testTextInput.enterText(texto);
      await tester.pump();
      await esperarBase(tester);
    }
  }

  EditableText editable(WidgetTester tester, String nombre) =>
      tester.widget<EditableText>(
        find.descendant(of: campo(nombre), matching: find.byType(EditableText)),
      );

  void comprobarFoco(WidgetTester tester, String nombre, String texto) {
    final segundo = editable(tester, nombre);
    // El foco sigue en este campo: ni en otra fila, ni en la búsqueda, ni en
    // el filtro.
    expect(
      FocusManager.instance.primaryFocus,
      same(segundo.focusNode),
      reason: 'el foco se movió',
    );
    expect(segundo.controller.text, texto);
  }

  for (final tamano in const [Size(1280, 800), Size(360, 640)]) {
    testWidgets('${tamano.width.toInt()}×${tamano.height.toInt()}: al '
        'escribir seguido en la segunda fila el foco y el texto se mantienen', (
      tester,
    ) async {
      await abrir(tester, tamano);
      await tester.ensureVisible(campo('Café molido 250 g'));
      await tester.pumpAndSettle();
      await tester.showKeyboard(campo('Café molido 250 g'));
      await tester.pump();

      await teclear(tester, '125');
      comprobarFoco(tester, 'Café molido 250 g', '125');
      expect(textoDe(tester, diferencia('Café molido 250 g')), '+104');
      expect(editable(tester, 'Arroz 500 g').controller.text, '');
      expect(editable(tester, 'Huevo AA').controller.text, '');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('con el filtro Sin contar la fila no se va mientras se escribe', (
    tester,
  ) async {
    await abrir(tester, const Size(1280, 800));
    await tester.tap(find.byKey(const Key('conteo_filtro_2')));
    await tester.pumpAndSettle();
    await tester.showKeyboard(campo('Café molido 250 g'));
    await tester.pump();

    await teclear(tester, '23');
    comprobarFoco(tester, 'Café molido 250 g', '23');
    // Al cambiar el filtro otra vez, la lista se recalcula.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byKey(const Key('conteo_filtro_2')));
    await tester.pumpAndSettle();
    expect(campo('Café molido 250 g'), findsNothing);
  });

  for (final tamano in const [
    Size(320, 568),
    Size(360, 640),
    Size(800, 700),
    Size(1024, 768),
    Size(1280, 800),
  ]) {
    testWidgets('sin desbordes en ${tamano.width.toInt()}×'
        '${tamano.height.toInt()} con todos los estados', (tester) async {
      await abrir(tester, tamano);
      await contar(tester, 'Arroz 500 g', '46');
      await contar(tester, 'Café molido 250 g', '-1');
      await contar(tester, 'Huevo AA', '78');
      await contar(tester, 'Queso costeño', '2,5');
      expect(tester.takeException(), isNull);
      await irArriba(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
