import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

import '../gestion_inventario/fakes_inventario.dart';
import '../pagos/fakes_pagos.dart';
import 'fakes_caja.dart';

/// calcularMargenes (CUS-09, RF-08, ERS 3.2.4).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  final desde = DateTime.utc(2026, 11, 5);
  final hasta = DateTime.utc(2026, 11, 12);

  late MovimientoRepositorioFalso movimientos;
  late ServicioReportes servicio;
  late ItemInventario huevo;
  late ItemInventario cafe;

  setUp(() {
    movimientos = MovimientoRepositorioFalso();
    servicio = ServicioReportes(
      VentaRepositorioFalso(),
      movimientos,
      CajaRepositorioFalso(),
      FiadoRepositorioFalso(),
      EstadoSincronizacionFalso(),
    );
    huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('100'),
    );
    cafe = ItemInventario(
      'i2',
      Producto('p2', 'C1', 'Café', UnidadMedida.unidad, null, d('8900')),
      d('10'),
    );
  });

  Future<void> vender(
    String id,
    ItemInventario item,
    DateTime fecha, {
    required String unidades,
    required String precio,
    String? costo,
    EstadoMovimiento estado = EstadoMovimiento.vigente,
  }) => movimientos.guardar(
    tienda,
    SalidaVenta(
      id,
      item,
      -d(unidades),
      fecha,
      Venta('v$id', const [], d(precio) * d(unidades), fecha),
      d(precio),
      costo == null ? null : d(costo),
    )..setEstado(estado),
  );

  Map<String, Decimal?> porId(Map<Producto, Decimal?> margenes) => {
    for (final e in margenes.entries) e.key.getId(): e.value,
  };

  test('suma el margen de varias ventas del mismo producto', () async {
    await vender(
      's1',
      huevo,
      DateTime.utc(2026, 11, 6),
      unidades: '10',
      precio: '550',
      costo: '400',
    );
    await vender(
      's2',
      huevo,
      DateTime.utc(2026, 11, 8),
      unidades: '30',
      precio: '600',
      costo: '400',
    );

    final margenes = await servicio.calcularMargenes(tienda, desde, hasta);

    // (550-400)x10 + (600-400)x30 = 1500 + 6000
    expect(porId(margenes), {'p1': d('7500')});
  });

  test(
    'calcula cada producto con el precio y el costo de sus salidas',
    () async {
      await vender(
        's1',
        huevo,
        DateTime.utc(2026, 11, 6),
        unidades: '2',
        precio: '550',
        costo: '400',
      );
      await vender(
        's2',
        cafe,
        DateTime.utc(2026, 11, 6),
        unidades: '1',
        precio: '8900',
        costo: '7000',
      );

      final margenes = await servicio.calcularMargenes(tienda, desde, hasta);

      expect(porId(margenes), {'p1': d('300'), 'p2': d('1900')});
    },
  );

  test(
    'producto con una salida sin costo queda como dato incompleto',
    () async {
      await vender(
        's1',
        cafe,
        DateTime.utc(2026, 11, 6),
        unidades: '3',
        precio: '8900',
      );
      await vender(
        's2',
        cafe,
        DateTime.utc(2026, 11, 7),
        unidades: '1',
        precio: '8900',
        costo: '7000',
      );
      await vender(
        's3',
        huevo,
        DateTime.utc(2026, 11, 7),
        unidades: '1',
        precio: '550',
        costo: '400',
      );

      final resultado = porId(
        await servicio.calcularMargenes(tienda, desde, hasta),
      );

      expect(resultado.containsKey('p2'), isTrue);
      expect(resultado['p2'], isNull);
      expect(resultado['p1'], d('150'));
    },
  );

  test('periodo sin ventas devuelve un mapa vacío', () async {
    expect(await servicio.calcularMargenes(tienda, desde, hasta), isEmpty);
  });

  test('las ventas fuera del periodo no cuentan', () async {
    await vender(
      's1',
      huevo,
      DateTime.utc(2026, 11, 4, 23),
      unidades: '5',
      precio: '550',
      costo: '400',
    );
    await vender(
      's2',
      huevo,
      hasta,
      unidades: '5',
      precio: '550',
      costo: '400',
    );
    await vender(
      's3',
      huevo,
      DateTime.utc(2026, 11, 5),
      unidades: '1',
      precio: '550',
      costo: '400',
    );

    final margenes = await servicio.calcularMargenes(tienda, desde, hasta);

    expect(porId(margenes), {'p1': d('150')});
  });

  test('las salidas que no están vigentes no cuentan', () async {
    await vender(
      's1',
      huevo,
      DateTime.utc(2026, 11, 6),
      unidades: '5',
      precio: '550',
      costo: '400',
      estado: EstadoMovimiento.anulado,
    );
    await vender(
      's2',
      cafe,
      DateTime.utc(2026, 11, 6),
      unidades: '1',
      precio: '8900',
      estado: EstadoMovimiento.anulado,
    );

    expect(await servicio.calcularMargenes(tienda, desde, hasta), isEmpty);
  });
}
