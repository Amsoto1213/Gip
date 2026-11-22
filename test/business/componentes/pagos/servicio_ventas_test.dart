import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import '../gestion_caja/fakes_caja.dart';
import '../gestion_inventario/fakes_catalogo.dart';
import '../gestion_inventario/fakes_inventario.dart';
import 'fakes_pagos.dart';

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  Decimal d(String v) => Decimal.parse(v);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late VentaRepositorioFalso ventas;
  late CajaRepositorioFalso cajas;
  late FiadoRepositorioFalso fiados;
  late ServicioFiados servicioFiados;
  late UnidadTrabajoFalsa unidad;
  late ServicioInventario inventario;
  late ServicioVentas servicio;
  late Producto arroz;
  late Producto cafe;
  late Producto queso;

  Producto producto(String id, String nombre, String? compra, String venta) =>
      Producto(
        id,
        id.toUpperCase(),
        nombre,
        UnidadMedida.unidad,
        compra == null ? null : d(compra),
        d(venta),
      );

  setUp(() async {
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    ventas = VentaRepositorioFalso();
    cajas = CajaRepositorioFalso();
    fiados = FiadoRepositorioFalso();
    unidad = UnidadTrabajoFalsa([items, movimientos, ventas, cajas, fiados]);
    fiados.unidad = unidad;
    servicioFiados = ServicioFiados(fiados);
    items.unidad = unidad;
    movimientos.unidad = unidad;
    ventas.unidad = unidad;
    cajas.unidad = unidad;
    inventario = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      ProductoRepositorioFalso(),
    );
    servicio = ServicioVentas(
      inventario,
      [
        ProcesadorPagoContado(ServicioCaja(cajas)),
        ProcesadorNequi(),
        ProcesadorFiado(servicioFiados),
      ],
      ventas,
      unidad,
    );
    arroz = producto('arroz', 'Arroz 500 g', '2000', '2800');
    cafe = producto('cafe', 'Café molido 250 g', null, '8900');
    queso = producto('queso', 'Queso costeño', '7000', '9000');
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    await items.guardarItem(tienda, ItemInventario('i-cafe', cafe, d('21')));
    await items.guardarItem(tienda, ItemInventario('i-queso', queso, d('0')));
    items.guardadosEnTransaccion.clear();
  });

  Future<Decimal> stock(Producto p) async =>
      (await items.buscarItem(tienda, p))!.getStockActual();

  group('agregarLinea', () {
    test('crea la línea con el ítem del producto', () async {
      final lineas = <LineaVenta>[];
      final linea = await servicio.agregarLinea(tienda, lineas, arroz, d('2'));

      expect(lineas, [linea]);
      expect(linea.getItem().getId(), 'i-arroz');
      expect(linea.getCantidad(), d('2'));
    });

    test(
      'si el producto ya está, suma la cantidad en la misma línea',
      () async {
        final lineas = <LineaVenta>[];
        final primera = await servicio.agregarLinea(
          tienda,
          lineas,
          arroz,
          d('2'),
        );
        final segunda = await servicio.agregarLinea(
          tienda,
          lineas,
          arroz,
          d('3'),
        );

        expect(segunda, same(primera));
        expect(lineas, hasLength(1));
        expect(primera.getCantidad(), d('5'));
      },
    );

    test('RN-01: sin existencia no crea la línea', () async {
      final lineas = <LineaVenta>[];
      await expectLater(
        servicio.agregarLinea(tienda, lineas, queso, d('1')),
        throwsA(isA<ExcepcionExistenciaInsuficiente>()),
      );
      expect(lineas, isEmpty);
    });

    test('RN-01: al sumar más de lo que hay, la línea queda igual', () async {
      final lineas = <LineaVenta>[];
      final linea = await servicio.agregarLinea(tienda, lineas, arroz, d('8'));
      await expectLater(
        servicio.agregarLinea(tienda, lineas, arroz, d('3')),
        throwsA(isA<ExcepcionExistenciaInsuficiente>()),
      );
      expect(linea.getCantidad(), d('8'));
    });

    test('rechaza una cantidad cero o negativa', () async {
      await expectLater(
        servicio.agregarLinea(tienda, [], arroz, d('0')),
        throwsA(isA<ExcepcionCantidadNoValida>()),
      );
    });

    test('rechaza un producto sin ítem', () async {
      await expectLater(
        servicio.agregarLinea(
          tienda,
          [],
          producto('x', 'Sin ítem', null, '1'),
          d('1'),
        ),
        throwsA(isA<ExcepcionProductoSinInventario>()),
      );
    });
  });

  group('cambiarCantidad', () {
    test('cambia la cantidad si hay existencia', () async {
      final linea = await servicio.agregarLinea(tienda, [], arroz, d('1'));
      servicio.cambiarCantidad(linea, d('10'));
      expect(linea.getCantidad(), d('10'));
    });

    test('RN-01 y cantidad > 0', () async {
      final linea = await servicio.agregarLinea(tienda, [], arroz, d('1'));
      expect(
        () => servicio.cambiarCantidad(linea, d('11')),
        throwsA(isA<ExcepcionExistenciaInsuficiente>()),
      );
      expect(
        () => servicio.cambiarCantidad(linea, d('0')),
        throwsA(isA<ExcepcionCantidadNoValida>()),
      );
      expect(linea.getCantidad(), d('1'));
    });
  });

  test('calcularTotal suma los subtotales', () async {
    final lineas = <LineaVenta>[];
    await servicio.agregarLinea(tienda, lineas, arroz, d('2'));
    await servicio.agregarLinea(tienda, lineas, cafe, d('1'));
    expect(servicio.calcularTotal(lineas), d('14500'));
    expect(servicio.calcularTotal([]), Decimal.zero);
  });

  group('crearPagoContado', () {
    test('cambio = recibido - a cubrir', () {
      final pago = servicio.crearPagoContado(d('13400'), d('20000'));
      expect(pago.getMontoRecibido(), d('20000'));
      expect(pago.getCambio(), d('6600'));
      expect(pago.calcularMontoCubierto(), d('13400'));
    });

    test('pago justo: cambio cero', () {
      expect(
        servicio.crearPagoContado(d('13400'), d('13400')).getCambio(),
        Decimal.zero,
      );
    });

    test('"El monto recibido no alcanza"', () {
      expect(
        () => servicio.crearPagoContado(d('13400'), d('10000')),
        throwsA(
          isA<ExcepcionMontoInsuficiente>().having(
            (e) => e.mensaje,
            'mensaje',
            'El monto recibido no alcanza',
          ),
        ),
      );
    });

    test('rechaza un monto a cubrir cero', () {
      expect(
        () => servicio.crearPagoContado(d('0'), d('0')),
        throwsA(isA<ExcepcionMontoNoValido>()),
      );
    });
  });

  group('crearPagoNequi', () {
    test('crea el pago; la referencia vacía queda nula', () {
      final pago = servicio.crearPagoNequi(d('11600'), '  ');
      expect(pago.getMonto(), d('11600'));
      expect(pago.getReferencia(), isNull);
      expect(servicio.crearPagoNequi(d('1'), ' 4471 ').getReferencia(), '4471');
    });

    test('rechaza monto cero o negativo', () {
      expect(
        () => servicio.crearPagoNequi(d('0'), null),
        throwsA(isA<ExcepcionMontoNoValido>()),
      );
    });
  });

  group('confirmar', () {
    Future<List<LineaVenta>> lineas(Map<Producto, String> pedido) async {
      final lineas = <LineaVenta>[];
      for (final e in pedido.entries) {
        await servicio.agregarLinea(tienda, lineas, e.key, d(e.value));
      }
      return lineas;
    }

    /// 5 arroz (14.000) + 2 café (17.800) + 1 dulce (200) = 32.000.
    Future<List<LineaVenta>> lineas32000() async {
      final dulce = producto('dulce', 'Dulce', null, '200');
      await items.guardarItem(tienda, ItemInventario('i-dulce', dulce, d('5')));
      final ls = await lineas({arroz: '5', cafe: '2', dulce: '1'});
      expect(servicio.calcularTotal(ls), d('32000'));
      return ls;
    }

    test('guarda la venta, una salida por línea y el ingreso en caja, en una '
        'sola transacción', () async {
      final ls = await lineas({arroz: '2', cafe: '1'}); // 5.600 + 8.900
      final pago = servicio.crearPagoContado(d('14500'), d('20000'));

      final venta = await servicio.confirmar(tienda, ls, [pago]);

      expect(unidad.transacciones, 1);
      expect(ventas.de(tienda), [venta]);
      expect(venta.getTotal(), d('14500'));
      expect(venta.getFormasPago(), [pago]);
      expect(venta.getFecha().isUtc, isTrue);

      final salidas = movimientos.de(tienda).cast<SalidaVenta>();
      expect(salidas, hasLength(2));
      final sArroz = salidas.firstWhere(
        (s) => s.getItem().getId() == 'i-arroz',
      );
      expect(sArroz.getCantidad(), d('-2'));
      expect(sArroz.getVentaId(), venta.getId());
      expect(sArroz.getPrecioUnitario(), d('2800'));
      expect(sArroz.getCostoUnitario(), d('2000'));
      final sCafe = salidas.firstWhere((s) => s.getItem().getId() == 'i-cafe');
      expect(sCafe.getCostoUnitario(), isNull);

      expect(await stock(arroz), d('8'));
      expect(await stock(cafe), d('20'));
      expect(cajas.movimientosDe(tienda).single.getValor(), d('14500'));

      expect([
        ...ventas.guardadosEnTransaccion,
        ...movimientos.guardadosEnTransaccion,
        ...items.guardadosEnTransaccion,
        ...cajas.guardadosEnTransaccion,
      ], everyElement(isTrue));
    });

    test('venta de 32.000 en efectivo con 50.000: a la caja entran 32.000 y '
        'el cambio es 18.000', () async {
      final ls = await lineas32000();

      final pago = servicio.crearPagoContado(d('32000'), d('50000'));
      expect(pago.getCambio(), d('18000'));

      await servicio.confirmar(tienda, ls, [pago]);

      final ingreso = cajas.movimientosDe(tienda).single;
      expect(ingreso.getValor(), d('32000'));
    });

    test('venta mixta de 32.000: 20.000 por Nequi y 12.000 en efectivo '
        'recibiendo 20.000; a la caja entran solo 12.000', () async {
      final ls = await lineas32000();

      final nequi = servicio.crearPagoNequi(d('20000'), '4471');
      final contado = servicio.crearPagoContado(d('12000'), d('20000'));
      expect(contado.getCambio(), d('8000'));

      final venta = await servicio.confirmar(tienda, ls, [nequi, contado]);

      expect(venta.getFormasPago(), [nequi, contado]);
      final movs = cajas.movimientosDe(tienda);
      expect(movs, hasLength(1));
      expect(movs.single.getValor(), d('12000'));
    });

    test('solo Nequi: no mueve la caja', () async {
      final ls = await lineas({arroz: '1'});
      await servicio.confirmar(tienda, ls, [
        servicio.crearPagoNequi(d('2800'), null),
      ]);
      expect(cajas.movimientos, isEmpty);
      expect(await stock(arroz), d('9'));
    });

    test('DI-21: una entrada registrada mientras la venta está abierta no se '
        'pierde (stock 10 + 5 - 2 = 13)', () async {
      final ls = await lineas({arroz: '2'}); // el ítem de la línea dice 10
      await inventario.registrarEntrada(tienda, arroz, d('5'), d('2000'), null);
      expect(await stock(arroz), d('15'));

      await servicio.confirmar(tienda, ls, [
        servicio.crearPagoContado(d('5600'), d('5600')),
      ]);

      expect(await stock(arroz), d('13'));
      expect(ls.single.getItem().getStockActual(), d('10'));
    });

    group('formas de pago no válidas: no se guarda nada', () {
      late List<LineaVenta> ls;
      setUp(() async => ls = await lineas({arroz: '2'})); // 5.600

      final casos = <String, List<FormaPago> Function()>{
        'sin formas': () => [],
        'no suman el total': () => [PagoNequi('n', d('5000'), null)],
        'pasan del total': () => [PagoNequi('n', d('6000'), null)],
        'repiten tipo': () => [
          PagoNequi('n1', d('2800'), null),
          PagoNequi('n2', d('2800'), null),
        ],
        'más de tres': () => [
          PagoNequi('n1', d('1400'), null),
          PagoContado('c1', d('1400'), d('0')),
          PagoNequi('n2', d('1400'), null),
          PagoContado('c2', d('1400'), d('0')),
        ],
        'una forma que no cubre nada': () => [
          PagoNequi('n', d('5600'), null),
          PagoContado('c', d('1000'), d('1000')),
        ],
      };
      for (final caso in casos.entries) {
        test(caso.key, () async {
          await expectLater(
            servicio.confirmar(tienda, ls, caso.value()),
            throwsA(
              isA<ExcepcionFormasPagoNoValidas>().having(
                (e) => e.mensaje,
                'mensaje',
                'Las formas de pago no cubren el total de la venta',
              ),
            ),
          );
          expect(unidad.transacciones, 0);
          expect(ventas.datos, isEmpty);
          expect(await stock(arroz), d('10'));
        });
      }
    });

    test('una venta sin líneas no se confirma', () async {
      await expectLater(
        servicio.confirmar(tienda, [], [PagoNequi('n', d('1'), null)]),
        throwsA(isA<ExcepcionFormasPagoNoValidas>()),
      );
    });

    test('stock negativo al confirmar: rollback, no se guarda nada', () async {
      final ls = await lineas({arroz: '2', cafe: '3'}); // 5.600 + 26.700
      // Otro dispositivo vendió café: ya no alcanza.
      final itemCafe = (await items.buscarItem(tienda, cafe))!
        ..setStockActual(d('2'));
      await items.guardarItem(tienda, itemCafe);

      await expectLater(
        servicio.confirmar(tienda, ls, [
          servicio.crearPagoContado(d('32300'), d('50000')),
        ]),
        throwsA(isA<ExcepcionStockNegativo>()),
      );

      expect(ventas.de(tienda), isEmpty);
      expect(movimientos.de(tienda), isEmpty);
      expect(cajas.movimientos[tienda.getId()] ?? [], isEmpty);
      expect(await stock(arroz), d('10'));
      expect(await stock(cafe), d('2'));
    });

    test('si falla la caja: rollback de la venta y las salidas', () async {
      final ls = await lineas({arroz: '2'});
      cajas.fallar = true;

      await expectLater(
        servicio.confirmar(tienda, ls, [
          servicio.crearPagoContado(d('5600'), d('10000')),
        ]),
        throwsA(isA<StateError>()),
      );

      expect(ventas.de(tienda), isEmpty);
      expect(movimientos.de(tienda), isEmpty);
      expect(await stock(arroz), d('10'));
      expect(ls.single.getItem().getStockActual(), d('10'));
    });

    group('con fiado (CUS-07)', () {
      late Cliente maria;
      setUp(() => maria = Cliente('c1', 'María Pérez', '3004124521'));

      Fiado fiar(String monto) => servicioFiados.crearFiado(maria, d(monto));

      test('fiado solo: guarda venta y fiado en la transacción y no toca la '
          'caja', () async {
        final ls = await lineas({arroz: '2'}); // 5.600
        final fiado = fiar('5600');

        final venta = await servicio.confirmar(tienda, ls, [fiado]);

        expect(unidad.transacciones, 1);
        expect(venta.getFormasPago(), [fiado]);
        expect(ventas.de(tienda), [venta]);
        expect(fiados.de(tienda), [fiado]);
        expect(fiados.guardadosEnTransaccion, [isTrue]);
        expect(cajas.movimientos, isEmpty);
        expect(await stock(arroz), d('8'));
        expect(maria.calcularSaldoPendiente(), d('5600'));
      });

      test('fiado + efectivo: a la caja entra solo el efectivo', () async {
        final ls = await lineas32000();
        final fiado = fiar('12000');
        final contado = servicio.crearPagoContado(d('20000'), d('20000'));

        await servicio.confirmar(tienda, ls, [contado, fiado]);

        expect(fiados.de(tienda), [fiado]);
        expect(cajas.movimientosDe(tienda).single.getValor(), d('20000'));
      });

      test('fiado + Nequi: no mueve la caja', () async {
        final ls = await lineas32000();
        final fiado = fiar('2000');
        final nequi = servicio.crearPagoNequi(d('30000'), '4471');

        await servicio.confirmar(tienda, ls, [nequi, fiado]);

        expect(fiados.de(tienda), [fiado]);
        expect(cajas.movimientos, isEmpty);
      });

      test('efectivo + Nequi + fiado: las tres formas', () async {
        final ls = await lineas32000();
        final formas = [
          servicio.crearPagoContado(d('10000'), d('20000')),
          servicio.crearPagoNequi(d('12000'), null),
          fiar('10000'),
        ];

        final venta = await servicio.confirmar(tienda, ls, formas);

        expect(venta.getFormasPago(), hasLength(3));
        expect(cajas.movimientosDe(tienda).single.getValor(), d('10000'));
        expect(fiados.de(tienda), hasLength(1));
      });

      test('dos fiados o un fiado que no completa el total: formas no '
          'válidas', () async {
        final ls = await lineas({arroz: '2'}); // 5.600
        for (final formas in [
          [fiar('2800'), fiar('2800')],
          [fiar('5000')],
          [fiar('6000')],
        ]) {
          await expectLater(
            servicio.confirmar(tienda, ls, formas),
            throwsA(isA<ExcepcionFormasPagoNoValidas>()),
          );
        }
        expect(ventas.de(tienda), isEmpty);
        expect(fiados.de(tienda), isEmpty);
      });

      test('si falla el guardado del fiado: rollback, no quedan venta, '
          'salidas, caja ni fiado', () async {
        final ls = await lineas({arroz: '2'}); // 5.600
        fiados.fallar = true;

        await expectLater(
          servicio.confirmar(tienda, ls, [
            servicio.crearPagoContado(d('600'), d('1000')),
            fiar('5000'),
          ]),
          throwsA(isA<StateError>()),
        );

        expect(ventas.de(tienda), isEmpty);
        expect(movimientos.de(tienda), isEmpty);
        expect(cajas.movimientos[tienda.getId()] ?? [], isEmpty);
        expect(fiados.de(tienda), isEmpty);
        expect(await stock(arroz), d('10'));
      });

      test(
        'stock negativo con fiado: rollback, el fiado no se guarda',
        () async {
          final ls = await lineas({arroz: '2'});
          // Otro movimiento deja el arroz en 1 antes de confirmar.
          final item = (await items.buscarItem(tienda, arroz))!;
          await items.guardarItem(
            tienda,
            ItemInventario(item.getId(), arroz, d('1')),
          );

          await expectLater(
            servicio.confirmar(tienda, ls, [fiar('5600')]),
            throwsA(isA<ExcepcionStockNegativo>()),
          );

          expect(ventas.de(tienda), isEmpty);
          expect(fiados.de(tienda), isEmpty);
        },
      );
    });
  });
}
