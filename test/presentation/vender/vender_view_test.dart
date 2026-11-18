import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/composition_root/registrar_alertas.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/composition_root/registrar_pagos.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/main.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:mocktail/mocktail.dart';

import '../negocio/alertas_falsos.dart';
import '../negocio/margen_falsos.dart';
import '../negocio/reporte_falsos.dart';
import '../surtido/existencias_falsos.dart';
import '../caja/caja_falsos.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// Prueba de punta a punta de CUS-02: la app con los módulos armados como en
/// `main.dart` sobre una base drift en memoria; solo el inicio de sesión es
/// falso. Buscar (CUS-06) → agregar → + → Cobrar → Confirmar.
void main() {
  final tienda = Tienda('1111', 'T001', 'Granero El Porvenir', 'Arjona');
  final UsuarioActivo carmen = (
    usuario: Administrador('2222', 'Carmen', '1000000001'),
    tienda: tienda,
  );
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late CoordinadoresInventario inventario;
  late CoordinadoresPagos pagos;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    final unidad = UnidadTrabajoDrift(base);
    inventario = registrarInventario(base, unidad);
    pagos = registrarPagos(
      base,
      unidad,
      inventario.servicioInventario,
      registrarCaja(base).servicioCaja,
    );
  });
  tearDown(() => base.close());

  Future<void> esperarBase(WidgetTester tester) async {
    // Las consultas de drift corren fuera del reloj falso de la prueba.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Crea el producto con [stock] unidades (CUS-18 + CUS-01).
  Future<Producto> crear(
    WidgetTester tester,
    String codigo,
    String nombre,
    String precio,
    String stock,
  ) async => (await tester.runAsync(() async {
    final p = await inventario.gestionarProducto.crearProducto(
      tienda,
      codigo,
      nombre,
      UnidadMedida.unidad,
      d('1000'),
      d(precio),
    );
    if (d(stock) > Decimal.zero) {
      await inventario.registrarEntradaMercancia.registrarEntrada(
        tienda,
        p,
        d(stock),
        d('1000'),
        null,
      );
    }
    return p;
  }))!;

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final autenticacion = AutenticacionFalsa();
    final sesionLocal = SesionLocalFalsa();
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);
    await tester.pumpWidget(
      GipApp(
        iniciarSesion: IniciarSesionCoordinator(
          ServicioAcceso(autenticacion, sesionLocal),
        ),
        gestionarProducto: inventario.gestionarProducto,
        buscarProducto: inventario.buscarProducto,
        registrarEntradaMercancia: inventario.registrarEntradaMercancia,
        registrarPerdida: inventario.registrarPerdida,
        registrarConteo: inventario.registrarConteo,
        consultarExistencias: ConsultarExistenciasFalso(),
        registrarVenta: pagos.registrarVenta,
        registrarFiado: pagos.registrarFiado,
        registrarAbono: pagos.registrarAbono,
        consultarCliente: pagos.consultarCliente,
        generarAlertas: GenerarAlertasFalso(),
        consultarAlertas: ConsultarAlertasFalso(),
        registrarVentaPerdida: registrarAlertas(
          base,
          ServicioAcceso(autenticacion, sesionLocal),
        ).registrarVentaPerdida,
        consultarMargen: ConsultarMargenFalso(),
        generarReporteDiario: GenerarReporteDiarioFalso(),
        registrarMovimientoCaja: RegistrarMovimientoCajaFalso(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Desde Vender: busca [texto] y elige [nombre].
  Future<void> agregar(WidgetTester tester, String texto, String nombre) async {
    await tester.tap(find.byKey(const Key('vender_buscar')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('buscar_texto')), texto);
    await esperarBase(tester);
    await tester.tap(find.text(nombre));
    await esperarBase(tester);
  }

  Future<Decimal> stock(WidgetTester tester, Producto p) async =>
      (await tester.runAsync(
        () => inventario.servicioInventario.obtenerItem(tienda, p),
      ))!.getStockActual();

  testWidgets('vender de contado: buscar, sumar, cobrar con cambio y '
      'confirmar', (tester) async {
    final arroz = await crear(tester, 'ARR', 'Arroz 500 g', '2800', '10');
    await abrir(tester);
    expect(
      find.text('Busque un producto para empezar la venta'),
      findsOneWidget,
    );

    await agregar(tester, 'arroz', 'Arroz 500 g');
    expect(find.text('Arroz 500 g'), findsOneWidget);
    expect(find.text('\$ 2.800 c/u'), findsOneWidget);

    await tester.tap(find.byKey(Key('vender_mas_${arroz.getId()}')));
    await esperarBase(tester);
    expect(
      tester
          .widget<Text>(find.byKey(Key('vender_cantidad_${arroz.getId()}')))
          .data,
      '2',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('vender_cobrar')),
        matching: find.text('\$ 5.600'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('vender_cobrar')));
    await tester.pumpAndSettle();
    expect(find.text('Cobrar'), findsWidgets);
    expect(find.text('\$ 5.600'), findsWidgets);

    await tester.enterText(find.byKey(const Key('cobrar_efectivo')), '10.000');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('cobrar_cambio'))).data,
      '\$ 4.400',
    );

    await tester.tap(find.byKey(const Key('cobrar_confirmar')));
    await esperarBase(tester);

    expect(find.text('Venta registrada'), findsOneWidget);
    expect(
      find.text('Busque un producto para empezar la venta'),
      findsOneWidget,
    );
    expect(await stock(tester, arroz), d('8'));
    final caja = (await tester.runAsync(
      () => base.select(base.movimientosCaja).getSingle(),
    ))!;
    expect(caja.valor, d('5600'));
  });

  testWidgets('sin existencia muestra el mensaje y no agrega (RN-01)', (
    tester,
  ) async {
    await crear(tester, 'QUE', 'Queso costeño', '9000', '0');
    await abrir(tester);

    await agregar(tester, 'queso', 'Queso costeño');

    expect(
      find.text('No hay suficiente existencia del producto'),
      findsOneWidget,
    );
    expect(
      find.text('Busque un producto para empezar la venta'),
      findsOneWidget,
    );
  });

  testWidgets('el monto insuficiente se muestra y no deja confirmar (5")', (
    tester,
  ) async {
    await crear(tester, 'ARR', 'Arroz 500 g', '2800', '10');
    await abrir(tester, tamano: const Size(360, 640));
    await agregar(tester, 'arroz', 'Arroz 500 g');
    await tester.tap(find.byKey(const Key('vender_cobrar')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('cobrar_efectivo')), '2.000');
    await tester.pumpAndSettle();

    expect(find.text('El monto recibido no alcanza'), findsOneWidget);
    expect(
      tester
          .widget<BotonPrimario>(find.byKey(const Key('cobrar_confirmar')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('pago mixto Nequi + efectivo en pantalla ancha', (tester) async {
    final arroz = await crear(tester, 'ARR', 'Arroz 500 g', '2800', '10');
    await abrir(tester, tamano: const Size(1280, 800));
    await agregar(tester, 'arroz', 'Arroz 500 g');
    await tester.tap(find.byKey(Key('vender_mas_${arroz.getId()}')));
    await esperarBase(tester);
    await tester.tap(find.byKey(const Key('vender_cobrar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('cobrar_nequi_monto')),
      '3.000',
    );
    await tester.enterText(
      find.byKey(const Key('cobrar_nequi_referencia')),
      '4471',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nequi · ref. 4471'), findsOneWidget);
    expect(find.text('Falta \$ 2.600'), findsOneWidget);

    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cobrar_sugerencia_1'))); // 5 mil
    await tester.pumpAndSettle();
    expect(find.text('Pago completo · cambio \$ 2.400'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cobrar_confirmar')));
    await esperarBase(tester);

    expect(find.text('Venta registrada'), findsOneWidget);
    final caja = (await tester.runAsync(
      () => base.select(base.movimientosCaja).getSingle(),
    ))!;
    expect(caja.valor, d('2600'));
    expect(tester.takeException(), isNull);
  });

  /// Lleva [buscador] a la vista y lo toca (en 5" la pantalla se desplaza).
  Future<void> tocar(WidgetTester tester, Finder buscador) async {
    await tester.ensureVisible(buscador);
    await tester.pumpAndSettle();
    await tester.tap(buscador);
    await tester.pumpAndSettle();
  }

  Future<int> contar(WidgetTester tester, String tabla) async =>
      (await tester.runAsync(
        () => base.customSelect('SELECT COUNT(*) AS n FROM $tabla').getSingle(),
      ))!.read<int>('n');

  testWidgets('fiar en 5": efectivo que no alcanza + fiado a un cliente '
      'nuevo, con los mensajes de nombre y monto (CUS-07)', (tester) async {
    final arroz = await crear(tester, 'ARR', 'Arroz 500 g', '2800', '10');
    await abrir(tester, tamano: const Size(360, 640));
    await agregar(tester, 'arroz', 'Arroz 500 g');
    await tester.tap(find.byKey(Key('vender_mas_${arroz.getId()}')));
    await esperarBase(tester);
    await tester.tap(find.byKey(const Key('vender_cobrar')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('cobrar_efectivo')), '2.000');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Fiado'));
    await tocar(tester, find.byKey(const Key('cobrar_fiar')));

    expect(find.text('Fiar parte de la venta'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('fiar_falta'))).data,
      '\$ 3.600',
    );
    expect(tester.takeException(), isNull);

    await tocar(tester, find.byKey(const Key('fiar_cliente_nuevo')));
    await tocar(tester, find.byKey(const Key('fiar_nuevo_registrar')));
    await esperarBase(tester);
    expect(find.text('El nombre del cliente es obligatorio'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('fiar_nuevo_nombre')),
      'Ana Gómez',
    );
    await tocar(tester, find.byKey(const Key('fiar_nuevo_registrar')));
    await esperarBase(tester);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(
      find.text('Ana quedará debiendo \$ 3.600 en total.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('fiar_monto')), '0');
    await tester.pumpAndSettle();
    await tocar(tester, find.byKey(const Key('fiar_agregar')));
    expect(
      find.text('El monto del fiado debe ser mayor que cero'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('fiar_monto')), '3.600');
    await tester.pumpAndSettle();
    await tocar(tester, find.byKey(const Key('fiar_agregar')));

    expect(find.text('Fiar parte de la venta'), findsNothing);
    expect(find.text('Fiado · Ana Gómez'), findsOneWidget);
    expect(find.text('Pago completo · cambio \$ 0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tocar(tester, find.byKey(const Key('cobrar_confirmar')));
    await esperarBase(tester);

    expect(find.text('Venta registrada'), findsOneWidget);
    expect(await contar(tester, 'fiados'), 1);
    expect(await contar(tester, 'clientes'), 1);
    final caja = (await tester.runAsync(
      () => base.select(base.movimientosCaja).getSingle(),
    ))!;
    expect(caja.valor, d('2000'));
  });

  testWidgets('fiar en la web: diálogo, busca sin tildes y fía toda la venta '
      'sin mover la caja (CUS-07)', (tester) async {
    await crear(tester, 'ARR', 'Arroz 500 g', '2800', '10');
    await tester.runAsync(
      () => pagos.registrarFiado.registrarCliente(
        tienda,
        'María Pérez',
        '300 412 4521',
      ),
    );
    await abrir(tester, tamano: const Size(1280, 800));
    await agregar(tester, 'arroz', 'Arroz 500 g');
    await tester.tap(find.byKey(const Key('vender_cobrar')));
    await tester.pumpAndSettle();

    await tocar(tester, find.text('Fiado'));
    await tocar(tester, find.byKey(const Key('cobrar_fiar')));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fiar_buscar')), 'MARIA');
    await esperarBase(tester);
    expect(find.text('300 412 4521 · al día'), findsOneWidget);
    expect(
      tester
          .widget<BotonPrimario>(find.byKey(const Key('fiar_agregar')))
          .onPressed,
      isNull,
    );

    await tocar(tester, find.text('María Pérez'));
    await tocar(tester, find.byKey(const Key('fiar_agregar')));

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Fiado · María Pérez'), findsOneWidget);
    await tocar(tester, find.byKey(const Key('cobrar_confirmar')));
    await esperarBase(tester);

    expect(find.text('Venta registrada'), findsOneWidget);
    expect(await contar(tester, 'fiados'), 1);
    expect(await contar(tester, 'movimientos_caja'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin existencia: "Anotar que se fue sin él" registra la venta '
      'perdida (CUS-13)', (tester) async {
    final queso = await crear(tester, 'QUE', 'Queso costeño', '9000', '0');
    await abrir(tester);

    await agregar(tester, 'queso', 'Queso costeño');
    expect(
      find.text('No hay suficiente existencia del producto'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('vender_anotar_perdida')), findsOneWidget);

    await tester.tap(find.byKey(const Key('vender_anotar_perdida')));
    await esperarBase(tester);

    expect(find.text('Venta perdida registrada'), findsOneWidget);
    expect(find.byKey(const Key('vender_anotar_perdida')), findsNothing);
    final filas = (await tester.runAsync(
      () => base.select(base.ventasPerdidas).get(),
    ))!;
    expect(filas.single.productoId, queso.getId());
    expect(filas.single.tiendaId, tienda.getId());
  });
}
