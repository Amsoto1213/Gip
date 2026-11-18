import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';

/// Lee con el repositorio real y falla al registrar el movimiento de caja,
/// para probar el rollback de toda la venta.
class CajaQueFalla implements ICajaRepositorio {
  CajaQueFalla(this._real);

  final ICajaRepositorio _real;

  @override
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha) =>
      _real.buscarPorFecha(tienda, fecha);

  @override
  Future<void> crear(Tienda tienda, Caja caja) => _real.crear(tienda, caja);

  @override
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  ) => throw StateError('falla del disco');

  @override
  Future<List<MovimientoCaja>> listarMovimientos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) => _real.listarMovimientos(tienda, desde, hasta);
}

/// CUS-02 de punta a punta sobre la base local: ServicioVentas con los
/// repositorios drift y la unidad de trabajo real.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidad;
  late InventarioRepositorioDrift items;
  late ServicioInventario inventario;
  late Producto arroz;
  late Producto cafe;

  ServicioVentas servicioVentas({ICajaRepositorio? cajas}) {
    return ServicioVentas(
      inventario,
      [
        ProcesadorPagoContado(
          ServicioCaja(cajas ?? CajaRepositorioDrift(base)),
        ),
        ProcesadorNequi(),
      ],
      VentaRepositorioDrift(base),
      unidad,
    );
  }

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidad = UnidadTrabajoDrift(base);
    items = InventarioRepositorioDrift(base);
    inventario = ServicioInventario(
      items,
      MovimientoInventarioRepositorioDrift(base),
      d('5'),
      unidad,
      ProductoRepositorioDrift(base),
    );
    final productos = ProductoRepositorioDrift(base);
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
      null,
      d('8900'),
    );
    await productos.guardar(tienda, arroz);
    await productos.guardar(tienda, cafe);
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    await items.guardarItem(tienda, ItemInventario('i-cafe', cafe, d('21')));
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  Future<Decimal> stock(Producto p) async =>
      (await items.buscarItem(tienda, p))!.getStockActual();

  Future<Map<String, int>> conteo() async => {
    for (final t in [
      'ventas',
      'formas_pago',
      'movimientos_inventario',
      'cajas',
      'movimientos_caja',
      'cola_pendientes',
    ])
      t: (await base.customSelect('SELECT COUNT(*) AS n FROM $t').getSingle())
          .read<int>('n'),
  };

  test('una venta mixta guarda venta, pagos, salidas, stock, caja y cola en '
      'una sola transacción', () async {
    final ventas = servicioVentas();
    final lineas = <LineaVenta>[];
    await ventas.agregarLinea(tienda, lineas, arroz, d('5')); // 14.000
    await ventas.agregarLinea(tienda, lineas, cafe, d('2')); // 17.800
    final total = ventas.calcularTotal(lineas);
    expect(total, d('31800'));

    final nequi = ventas.crearPagoNequi(d('20000'), '4471');
    final contado = ventas.crearPagoContado(d('11800'), d('20000'));
    final venta = await ventas.confirmar(tienda, lineas, [nequi, contado]);

    expect(await stock(arroz), d('5'));
    expect(await stock(cafe), d('19'));

    final filaVenta = await base.select(base.ventas).getSingle();
    expect(filaVenta.id, venta.getId());
    expect(filaVenta.total, d('31800'));
    expect(filaVenta.tiendaId, 't1');

    final formas = {
      for (final f in await base.select(base.formasPago).get()) f.tipo: f,
    };
    expect(formas['NEQUI']!.monto, d('20000'));
    expect(formas['NEQUI']!.referencia, '4471');
    expect(formas['CONTADO']!.montoRecibido, d('20000'));
    expect(formas['CONTADO']!.cambio, d('8200'));

    final salidas = await base.select(base.movimientosInventario).get();
    expect(salidas, hasLength(2));
    final sArroz = salidas.firstWhere((s) => s.itemId == 'i-arroz');
    expect(sArroz.tipo, 'SALIDA_VENTA');
    expect(sArroz.cantidad, d('-5'));
    expect(sArroz.ventaId, venta.getId());
    expect(sArroz.precioUnitario, d('2800'));
    expect(sArroz.costoUnitario, d('2000'));
    final sCafe = salidas.firstWhere((s) => s.itemId == 'i-cafe');
    expect(sCafe.costoUnitario, isNull);

    final movCaja = await base.select(base.movimientosCaja).getSingle();
    expect(movCaja.valor, d('11800'));
    expect(movCaja.tipo, 'INGRESO');
    expect(movCaja.descripcion, 'Venta ${venta.getId()}');

    // ventas 1 + formas 2 + salidas 2 + ítems 2 + caja 1 + mov. caja 1.
    final cola = await base.select(base.colaPendientes).get();
    expect(cola.map((c) => c.tabla).toList()..sort(), [
      'cajas',
      'formas_pago',
      'formas_pago',
      'items_inventario',
      'items_inventario',
      'movimientos_caja',
      'movimientos_inventario',
      'movimientos_inventario',
      'ventas',
    ]);
    expect(cola.every((c) => c.tiendaId == 't1'), isTrue);
  });

  test('stock 10, entrada de 5 con la venta abierta, venta de 2: el stock '
      'final es 13 (DI-21)', () async {
    final ventas = servicioVentas();
    final lineas = <LineaVenta>[];
    await ventas.agregarLinea(tienda, lineas, arroz, d('2'));

    await inventario.registrarEntrada(tienda, arroz, d('5'), d('2000'), null);
    expect(await stock(arroz), d('15'));

    await ventas.confirmar(tienda, lineas, [
      ventas.crearPagoContado(d('5600'), d('10000')),
    ]);

    expect(await stock(arroz), d('13'));
  });

  test('la venta guarda el costo de la última entrada; las anteriores no '
      'cambian (DI-33)', () async {
    final ventas = servicioVentas();
    Future<void> venderUnCafe() async {
      final lineas = <LineaVenta>[];
      await ventas.agregarLinea(tienda, lineas, cafe, d('1'));
      await ventas.confirmar(tienda, lineas, [
        ventas.crearPagoContado(d('8900'), d('10000')),
      ]);
    }

    Future<List<Decimal?>> costosVendidos() async {
      final consulta = base.select(base.movimientosInventario)
        ..where((m) => m.tipo.equals('SALIDA_VENTA'))
        ..orderBy([(m) => OrderingTerm.asc(m.fecha)]);
      return [for (final s in await consulta.get()) s.costoUnitario];
    }

    // El café se creó sin precio de compra: esa venta queda sin costo.
    await venderUnCafe();
    await inventario.registrarEntrada(tienda, cafe, d('10'), d('6000'), null);
    await venderUnCafe();
    await inventario.registrarEntrada(tienda, cafe, d('5'), d('6500'), null);
    await venderUnCafe();

    expect(await costosVendidos(), [null, d('6000'), d('6500')]);
    final guardado = await ProductoRepositorioDrift(base)
        .buscarPorId(tienda, cafe.getId());
    expect(guardado!.getPrecioCompra(), d('6500'));
  });

  test('si el stock quedaría negativo no se guarda nada', () async {
    final ventas = servicioVentas();
    final lineas = <LineaVenta>[];
    await ventas.agregarLinea(tienda, lineas, arroz, d('2'));
    await ventas.agregarLinea(tienda, lineas, cafe, d('3'));
    // Mientras tanto se vendió café en otra venta: quedan 2.
    await items.guardarItem(tienda, ItemInventario('i-cafe', cafe, d('2')));
    await base.delete(base.colaPendientes).go();

    await expectLater(
      ventas.confirmar(tienda, lineas, [
        ventas.crearPagoContado(d('32300'), d('50000')),
      ]),
      throwsA(isA<ExcepcionStockNegativo>()),
    );

    expect(await conteo(), {
      'ventas': 0,
      'formas_pago': 0,
      'movimientos_inventario': 0,
      'cajas': 0,
      'movimientos_caja': 0,
      'cola_pendientes': 0,
    });
    expect(await stock(arroz), d('10'));
    expect(await stock(cafe), d('2'));
  });

  test(
    'si falla la caja no se guarda nada, ni la venta ni las salidas',
    () async {
      final ventas = servicioVentas(
        cajas: CajaQueFalla(CajaRepositorioDrift(base)),
      );
      final lineas = <LineaVenta>[];
      await ventas.agregarLinea(tienda, lineas, arroz, d('2'));

      await expectLater(
        ventas.confirmar(tienda, lineas, [
          ventas.crearPagoContado(d('5600'), d('10000')),
        ]),
        throwsA(isA<StateError>()),
      );

      expect((await conteo()).values, everyElement(0));
      expect(await stock(arroz), d('10'));
    },
  );
}
