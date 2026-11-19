import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/composition_root/registrar_pagos.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/presentation/caja/ventas_hoy_view.dart';
import 'package:gip/presentation/caja/ventas_hoy_view_model.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// Prueba de punta a punta de CUS-20: la vista con el módulo armado como en
/// `main.dart` y una base drift en memoria.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late InventarioRepositorioDrift items;
  late ServicioVentas servicioVentas;
  late ServicioFiados servicioFiados;
  late ServicioClientes servicioClientes;
  late Producto arroz;
  late Producto cafe;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    final unidad = UnidadTrabajoDrift(base);
    items = InventarioRepositorioDrift(base);
    final inventario = ServicioInventario(
      items,
      MovimientoInventarioRepositorioDrift(base),
      d('5'),
      unidad,
      ProductoRepositorioDrift(base),
    );
    servicioFiados = ServicioFiados(FiadoRepositorioDrift(base));
    servicioClientes = ServicioClientes(ClienteRepositorioDrift(base));
    servicioVentas = ServicioVentas(
      inventario,
      [
        ProcesadorPagoContado(ServicioCaja(CajaRepositorioDrift(base))),
        ProcesadorNequi(),
        ProcesadorFiado(servicioFiados),
      ],
      VentaRepositorioDrift(base),
      unidad,
    );
    arroz = Producto(
      'p-arroz',
      'ARR',
      'Arroz 500 g',
      UnidadMedida.unidad,
      d('2000'),
      d('2800'),
    );
    cafe = Producto(
      'p-cafe',
      'CAF',
      'Café molido 250 g',
      UnidadMedida.unidad,
      d('6000'),
      d('8900'),
    );
    final productos = ProductoRepositorioDrift(base);
    await productos.guardar(tienda, arroz);
    await productos.guardar(tienda, cafe);
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    await items.guardarItem(tienda, ItemInventario('i-cafe', cafe, d('21')));
  });
  tearDown(() => base.close());

  Future<Decimal> stock(Producto p) async =>
      (await items.buscarItem(tienda, p))!.getStockActual();

  /// Vende 3 de arroz y 1 de café (17.300) de contado.
  Future<Venta> ventaDeContado(WidgetTester tester) async {
    return (await tester.runAsync(() async {
      final lineas = <LineaVenta>[];
      await servicioVentas.agregarLinea(tienda, lineas, arroz, d('3'));
      await servicioVentas.agregarLinea(tienda, lineas, cafe, d('1'));
      final total = servicioVentas.calcularTotal(lineas);
      return servicioVentas.confirmar(tienda, lineas, [
        servicioVentas.crearPagoContado(total, total),
      ]);
    }))!;
  }

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(1280, 800),
    Usuario? usuario,
  }) async {
    final pagos = registrarAnularVenta(
      servicioVentas,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => VentasHoyViewModel(pagos, (
            usuario: usuario ?? Administrador('2222', 'Carmen Ruiz', '1'),
            tienda: tienda,
          ))..elegirPeriodo(PeriodoVentas.hoy),
          child: const VentasHoyView(),
        ),
      ),
    );
    await esperarBase(tester);
  }

  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
    await tester.tap(objetivo);
    await tester.pumpAndSettle();
  }

  testWidgets('en escritorio muestra la tabla con los productos, el pago y el '
      'total', (tester) async {
    await ventaDeContado(tester);
    await abrir(tester);

    expect(find.text('Ventas de hoy'), findsWidgets);
    expect(find.text('Arroz 500 g, Café molido 250 g'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text(r'$ 17.300'), findsOneWidget);
    expect(find.text('Anular'), findsOneWidget);
    expect(find.text('1 venta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('anular: la confirmación dice qué pasará y, al confirmar con el '
      'motivo, deja la venta anulada', (tester) async {
    final venta = await ventaDeContado(tester);
    await abrir(tester);

    await tocar(tester, find.byKey(Key('anular_${venta.getId()}')));

    expect(find.byKey(const Key('anular_dialogo')), findsOneWidget);
    expect(find.textContaining('¿Anular la venta de las'), findsOneWidget);
    expect(find.text('Los 2 productos vuelven al surtido.'), findsOneWidget);
    expect(find.text(r'Salen $ 17.300 de la caja de hoy.'), findsOneWidget);
    expect(
      find.text('Queda anotado que usted la anuló. No se puede deshacer.'),
      findsOneWidget,
    );
    expect(find.text('Motivo (obligatorio)'), findsOneWidget);

    await tester.tap(find.text('Cliente devolvió'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('anular_confirmar')));
    await esperarBase(tester);

    expect(find.byKey(const Key('ventas_aviso')), findsOneWidget);
    expect(find.text('Venta anulada'), findsOneWidget);
    expect(find.text('Anulada'), findsOneWidget);
    expect(find.text('Anular'), findsNothing);
    final tachado = tester.widget<Text>(find.text(r'$ 17.300'));
    expect(tachado.style?.decoration, TextDecoration.lineThrough);
    expect(await tester.runAsync(() => stock(arroz)), d('10'));
    final fila = (await tester.runAsync(
      () => base.select(base.anulacionesVenta).getSingle(),
    ))!;
    expect(fila.motivo, 'Cliente devolvió');
    expect(fila.usuarioNombre, 'Carmen Ruiz');
  });

  testWidgets('"No, dejarla como está" no cambia nada', (tester) async {
    final venta = await ventaDeContado(tester);
    await abrir(tester);

    await tocar(tester, find.byKey(Key('anular_${venta.getId()}')));
    await tester.tap(find.byKey(const Key('anular_cancelar')));
    await esperarBase(tester);

    expect(find.byKey(const Key('anular_dialogo')), findsNothing);
    expect(find.text('Anular'), findsOneWidget);
    expect(find.text('Venta anulada'), findsNothing);
    expect(await tester.runAsync(() => stock(arroz)), d('7'));
  });

  testWidgets('"Otro…" exige escribir el motivo', (tester) async {
    final venta = await ventaDeContado(tester);
    await abrir(tester);
    await tocar(tester, find.byKey(Key('anular_${venta.getId()}')));

    await tester.tap(find.text('Otro…'));
    await tester.pump();
    botonDeConfirmar() => tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('anular_confirmar')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(botonDeConfirmar().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('anular_motivo_otro')),
      'Producto vencido',
    );
    await tester.pump();
    expect(botonDeConfirmar().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('anular_confirmar')));
    await esperarBase(tester);

    final fila = (await tester.runAsync(
      () => base.select(base.anulacionesVenta).getSingle(),
    ))!;
    expect(fila.motivo, 'Producto vencido');
  });

  testWidgets('con la caja de hoy cerrada no se anula y lo dice', (
    tester,
  ) async {
    final venta = await ventaDeContado(tester);
    await tester.runAsync(
      () =>
          ServicioCaja(CajaRepositorioDrift(base))
              .cerrarCaja(tienda, d('17300')),
    );
    await abrir(tester);

    await tocar(tester, find.byKey(Key('anular_${venta.getId()}')));
    await tester.tap(find.byKey(const Key('anular_confirmar')));
    await esperarBase(tester);

    expect(find.text('La caja de hoy ya está cerrada'), findsOneWidget);
    expect(find.text('Venta anulada'), findsNothing);
    expect(find.text('Anular'), findsOneWidget);
    expect(await tester.runAsync(() => stock(arroz)), d('7'));
    expect(
      await tester.runAsync(() => base.select(base.anulacionesVenta).get()),
      isEmpty,
    );
  });

  testWidgets('en el móvil se toca la fila y la hoja pide el motivo', (
    tester,
  ) async {
    final venta = await ventaDeContado(tester);
    await abrir(tester, tamano: const Size(390, 844));
    expect(find.text('Hoy'), findsWidgets);
    expect(find.textContaining('2 productos'), findsOneWidget);

    await tocar(tester, find.byKey(Key('venta_${venta.getId()}')));

    expect(find.byKey(const Key('anular_hoja')), findsOneWidget);
    expect(find.text('Los 2 productos vuelven al surtido.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('anular_confirmar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('anular_confirmar')));
    await esperarBase(tester);

    expect(find.text('Venta anulada'), findsOneWidget);
    expect(find.text('Anulada'), findsOneWidget);
    expect(await tester.runAsync(() => stock(arroz)), d('10'));
  });

  testWidgets('una venta fiada dice que el fiado queda anulado, sin caja', (
    tester,
  ) async {
    final maria = (await tester.runAsync(
      () => servicioClientes.registrarCliente(tienda, 'María Pérez', ''),
    ))!;
    final venta = (await tester.runAsync(() async {
      final lineas = <LineaVenta>[];
      await servicioVentas.agregarLinea(tienda, lineas, arroz, d('2'));
      return servicioVentas.confirmar(tienda, lineas, [
        servicioFiados.crearFiado(maria, servicioVentas.calcularTotal(lineas)),
      ]);
    }))!;
    await abrir(tester);

    expect(find.text('Fiado'), findsOneWidget);
    await tocar(tester, find.byKey(Key('anular_${venta.getId()}')));

    expect(find.text(r'El fiado de $ 5.600 queda anulado.'), findsOneWidget);
    expect(find.textContaining('de la caja de hoy'), findsNothing);
    expect(find.text('El producto vuelve al surtido.'), findsOneWidget);
  });

  testWidgets('sin ventas dice que todavía no hay', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('ventas_vacio')), findsOneWidget);
    expect(find.text('Todavía no hay ventas hoy.'), findsOneWidget);

    await tester.tap(find.text('Ayer'));
    await esperarBase(tester);

    expect(find.text('Ventas de ayer'), findsWidgets);
    expect(find.text('No hay ventas en este periodo.'), findsOneWidget);
  });

  testWidgets('el empleado ve el rechazo y no puede anular', (tester) async {
    await ventaDeContado(tester);
    await abrir(tester, usuario: Empleado('3333', 'Luis', '2'));

    expect(
      find.text('Solo el propietario de la tienda puede hacer esto'),
      findsOneWidget,
    );
    expect(find.text('Anular'), findsNothing);
  });

  testWidgets('sin desbordes en 360×640 con la hoja abierta y áreas de 44 px', (
    tester,
  ) async {
    final venta = await ventaDeContado(tester);
    await abrir(tester, tamano: const Size(360, 640));
    expect(tester.takeException(), isNull);

    await tocar(tester, find.byKey(Key('venta_${venta.getId()}')));
    await tester.tap(find.text('Otro…'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (final clave in ['anular_confirmar', 'anular_cancelar']) {
      await tester.ensureVisible(find.byKey(Key(clave)));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(Key(clave))).height,
        greaterThanOrEqualTo(44),
        reason: clave,
      );
    }
  });
}

Future<void> esperarBase(WidgetTester tester) async {
  // Las consultas de drift corren fuera del reloj falso de la prueba.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pumpAndSettle();
}
