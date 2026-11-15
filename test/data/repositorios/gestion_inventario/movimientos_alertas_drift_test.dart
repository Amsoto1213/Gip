import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';

/// listarSalidas y buscarFechaPrimerMovimiento (CUS-24, DI-25).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late MovimientoInventarioRepositorioDrift movimientos;
  late ItemInventario item;
  late ItemInventario otroItem;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    movimientos = MovimientoInventarioRepositorioDrift(base);
    final productos = ProductoRepositorioDrift(base);
    final items = InventarioRepositorioDrift(base);
    final coco = Producto(
      'p1',
      'C1',
      'Coco',
      UnidadMedida.unidad,
      null,
      d('3000'),
    );
    final panela = Producto(
      'p2',
      'P1',
      'Panela',
      UnidadMedida.unidad,
      null,
      d('2500'),
    );
    await productos.guardar(tienda, coco);
    await productos.guardar(tienda, panela);
    item = ItemInventario('i1', coco, d('5'));
    otroItem = ItemInventario('i2', panela, d('5'));
    await items.guardarItem(tienda, item);
    await items.guardarItem(tienda, otroItem);
  });
  tearDown(() => base.close());

  Future<SalidaVenta> salida(
    String id,
    ItemInventario deItem,
    DateTime fecha, {
    String cantidad = '-2',
  }) async {
    final venta = Venta('v$id', const [], d('6000'), fecha);
    await base
        .into(base.ventas)
        .insert(
          VentasCompanion.insert(
            id: venta.getId(),
            tiendaId: tienda.getId(),
            fecha: fecha,
            total: d('6000'),
          ),
        );
    final s = SalidaVenta(
      id,
      deItem,
      d(cantidad),
      fecha,
      venta,
      d('3000'),
      null,
    );
    await movimientos.guardar(tienda, s);
    return s;
  }

  group('listarSalidas', () {
    final desde = DateTime.utc(2026, 10, 16);
    final hasta = DateTime.utc(2026, 11, 15);

    test(
      'trae las salidas del ítem dentro del periodo, sin incluir hasta',
      () async {
        await salida('s1', item, DateTime.utc(2026, 10, 15, 23));
        await salida('s2', item, DateTime.utc(2026, 10, 16));
        await salida(
          's3',
          item,
          DateTime.utc(2026, 11, 14, 20),
          cantidad: '-3',
        );
        await salida('s4', item, hasta);
        await salida('s5', otroItem, DateTime.utc(2026, 11, 1));

        final salidas = await movimientos.listarSalidas(item, desde, hasta);

        expect(salidas.map((s) => s.getId()), ['s3', 's2']);
        expect(salidas.first.calcularUnidades(), d('3'));
        expect(salidas.first.getVenta().getId(), 'vs3');
        expect(salidas.first.getVenta().getTotal(), d('6000'));
      },
    );

    test('no trae entradas ni salidas que no estén vigentes', () async {
      await movimientos.guardar(
        tienda,
        EntradaMercancia(
          'e1',
          item,
          d('24'),
          DateTime.utc(2026, 11, 1),
          d('2000'),
          null,
        ),
      );
      final enRevision = await salida('s1', item, DateTime.utc(2026, 11, 2));
      enRevision.setEstado(EstadoMovimiento.enRevision);
      await (base.update(
        base.movimientosInventario,
      )..where((m) => m.id.equals('s1'))).write(
        const MovimientosInventarioCompanion(estado: Value('EN_REVISION')),
      );

      expect(await movimientos.listarSalidas(item, desde, hasta), isEmpty);
    });
  });

  group('buscarFechaPrimerMovimiento', () {
    test('sin movimientos es null', () async {
      expect(await movimientos.buscarFechaPrimerMovimiento(item), isNull);
    });

    test('es la fecha más antigua del ítem, de cualquier tipo', () async {
      await salida('s1', item, DateTime.utc(2026, 11, 10));
      await movimientos.guardar(
        tienda,
        EntradaMercancia(
          'e1',
          item,
          d('24'),
          DateTime.utc(2026, 11, 2, 9),
          d('2000'),
          null,
        ),
      );
      await salida('s2', otroItem, DateTime.utc(2026, 10, 1));

      expect(
        await movimientos.buscarFechaPrimerMovimiento(item),
        DateTime.utc(2026, 11, 2, 9),
      );
    });
  });
}
