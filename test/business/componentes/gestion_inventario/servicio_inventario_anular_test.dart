import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';

import 'fakes_catalogo.dart';
import 'fakes_inventario.dart';

/// Anular las salidas de una venta (CUS-20, RNF-15): el stock vuelve.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15, 15);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late ProductoRepositorioFalso productos;
  late UnidadTrabajoFalsa unidad;
  late ServicioInventario servicio;
  late ItemInventario arroz;
  late ItemInventario cafe;

  setUp(() async {
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    productos = ProductoRepositorioFalso();
    unidad = UnidadTrabajoFalsa([items, movimientos, productos]);
    items.unidad = unidad;
    movimientos.unidad = unidad;
    servicio = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      productos,
    );
    arroz = ItemInventario(
      'i1',
      Producto('p1', 'ARR', 'Arroz', UnidadMedida.unidad, d('2000'), d('2800')),
      d('7'),
    );
    cafe = ItemInventario(
      'i2',
      Producto('p2', 'CAF', 'Café', UnidadMedida.unidad, null, d('8900')),
      d('20'),
    );
    await items.guardarItem(tienda, arroz);
    await items.guardarItem(tienda, cafe);
    items.guardadosEnTransaccion.clear();
  });

  Venta venta(String id) => Venta(id, const [], d('1'), fecha);

  SalidaVenta salida(String id, ItemInventario item, String cant, Venta v) =>
      SalidaVenta(id, item, -d(cant), fecha, v.getId(), d('1'), null);

  Future<Decimal> stock(ItemInventario i) async =>
      (await items.buscarItem(tienda, i.getProducto()))!.getStockActual();

  group('anularMovimiento', () {
    test('marca la salida ANULADO y devuelve su cantidad al stock', () async {
      final s = salida('s1', arroz, '3', venta('v1'));

      await servicio.anularMovimiento(tienda, s);

      expect(s.getEstado(), EstadoMovimiento.anulado);
      expect(arroz.getStockActual(), d('10'));
      expect(await stock(arroz), d('10'));
      expect(movimientos.estadosActualizados, [s]);
      // Todo ocurrió dentro de una transacción.
      expect(movimientos.guardadosEnTransaccion.last, isTrue);
      expect(items.guardadosEnTransaccion.single, isTrue);
    });

    test('también anula una entrada: el stock baja lo que subió', () async {
      final e = EntradaMercancia('e1', arroz, d('4'), fecha, d('2000'), null);

      await servicio.anularMovimiento(tienda, e);

      expect(await stock(arroz), d('3'));
      expect(e.getEstado(), EstadoMovimiento.anulado);
    });

    test('rechaza si el stock quedaría negativo y no cambia nada', () async {
      final e = EntradaMercancia('e1', arroz, d('9'), fecha, d('2000'), null);

      await expectLater(
        servicio.anularMovimiento(tienda, e),
        throwsA(isA<ExcepcionStockNegativo>()),
      );

      expect(e.getEstado(), EstadoMovimiento.vigente);
      expect(arroz.getStockActual(), d('7'));
      expect(await stock(arroz), d('7'));
      expect(movimientos.estadosActualizados, isEmpty);
    });

    test('si falla el guardado, el movimiento y el ítem conservan lo '
        'anterior', () async {
      final s = salida('s1', arroz, '3', venta('v1'));
      movimientos.fallarActualizarEstado = true;

      await expectLater(servicio.anularMovimiento(tienda, s), throwsStateError);

      expect(s.getEstado(), EstadoMovimiento.vigente);
      expect(arroz.getStockActual(), d('7'));
      expect(await stock(arroz), d('7'));
    });
  });

  group('anularSalidas', () {
    test('anula todas las salidas vigentes de la venta y devuelve el '
        'stock', () async {
      final v = venta('v1');
      await movimientos.guardar(tienda, salida('s1', arroz, '3', v));
      await movimientos.guardar(tienda, salida('s2', cafe, '2', v));

      await servicio.anularSalidas(tienda, v.getId());

      expect(await stock(arroz), d('10'));
      expect(await stock(cafe), d('22'));
      expect(movimientos.estadosActualizados, hasLength(2));
    });

    test('no toca las salidas de otras ventas', () async {
      final v1 = venta('v1');
      final v2 = venta('v2');
      await movimientos.guardar(tienda, salida('s1', arroz, '3', v1));
      final otraSalida = salida('s2', arroz, '1', v2);
      await movimientos.guardar(tienda, otraSalida);

      await servicio.anularSalidas(tienda, v1.getId());

      expect(otraSalida.getEstado(), EstadoMovimiento.vigente);
      expect(await stock(arroz), d('10'));
    });

    test('una salida que ya estaba anulada no devuelve el stock dos '
        'veces', () async {
      final v = venta('v1');
      final s = salida('s1', arroz, '3', v)
        ..setEstado(EstadoMovimiento.anulado);
      await movimientos.guardar(tienda, s);

      await servicio.anularSalidas(tienda, v.getId());

      expect(await stock(arroz), d('7'));
      expect(movimientos.estadosActualizados, isEmpty);
    });

    test('una venta sin salidas no hace nada', () async {
      await servicio.anularSalidas(tienda, 'v9');

      expect(movimientos.estadosActualizados, isEmpty);
    });
  });

  group('listarSalidasDeVentas', () {
    test('agrupa las salidas por el id de cada venta, en cualquier '
        'estado', () async {
      final v1 = venta('v1');
      final v2 = venta('v2');
      await movimientos.guardar(tienda, salida('s1', arroz, '3', v1));
      await movimientos.guardar(
        tienda,
        salida('s2', cafe, '2', v1)..setEstado(EstadoMovimiento.anulado),
      );
      await movimientos.guardar(tienda, salida('s3', arroz, '1', v2));

      final porVenta = await servicio.listarSalidasDeVentas(tienda, [
        v1.getId(),
        v2.getId(),
      ]);

      expect(porVenta['v1']!.map((s) => s.getId()), ['s1', 's2']);
      expect(porVenta['v2']!.map((s) => s.getId()), ['s3']);
    });

    test('sin ventas devuelve vacío', () async {
      expect(await servicio.listarSalidasDeVentas(otra, const []), isEmpty);
    });
  });
}
