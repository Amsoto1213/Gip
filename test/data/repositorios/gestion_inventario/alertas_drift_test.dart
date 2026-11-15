import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/alerta_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/venta_perdida_repositorio_drift.dart';

/// AlertaRepositorioDrift y VentaPerdidaRepositorioDrift (CUS-24, CUS-05).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  final hoy = DateTime(2026, 11, 15);
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late AlertaRepositorioDrift alertas;
  late VentaPerdidaRepositorioDrift perdidas;
  late Producto coco;
  late Producto platano;
  late ItemInventario itemCoco;
  late ItemInventario itemPlatano;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    alertas = AlertaRepositorioDrift(base);
    perdidas = VentaPerdidaRepositorioDrift(base);
    final productos = ProductoRepositorioDrift(base);
    final items = InventarioRepositorioDrift(base);
    coco = Producto('p1', 'C1', 'Coco', UnidadMedida.unidad, null, d('3000'));
    platano = Producto(
      'p2',
      'P1',
      'Plátano',
      UnidadMedida.unidad,
      null,
      d('800'),
    );
    await productos.guardar(tienda, coco);
    await productos.guardar(tienda, platano);
    itemCoco = ItemInventario('i1', coco, d('2'));
    itemPlatano = ItemInventario('i2', platano, d('18'));
    await items.guardarItem(tienda, itemCoco);
    await items.guardarItem(tienda, itemPlatano);
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  AlertaReabastecimiento alerta(
    String id,
    ItemInventario item, {
    String dias = '1',
    bool provisional = false,
  }) => AlertaReabastecimiento(
    id,
    item,
    hoy,
    item.getStockActual(),
    d('2.3'),
    d(dias),
    provisional,
  );

  Future<List<EntradaCola>> cola() => base.select(base.colaPendientes).get();

  group('AlertaRepositorioDrift', () {
    test('guarda y lee las alertas del día con su ítem y producto', () async {
      await alertas.reemplazar(tienda, hoy, [
        alerta('a1', itemCoco, dias: '0.87', provisional: true),
      ]);

      final leidas = await alertas.listarPorFecha(tienda, hoy);
      final a = leidas.single;
      expect(a.getId(), 'a1');
      expect(a.getItem().getProducto().getNombre(), 'Coco');
      expect(a.getFecha(), hoy);
      expect(a.getExistencia(), d('2'));
      expect(a.getConsumoPromedioDiario(), d('2.3'));
      expect(a.getDiasCobertura(), d('0.87'));
      expect(a.isProvisional(), isTrue);
    });

    test('reemplazar no duplica: deja solo las del último cálculo', () async {
      await alertas.reemplazar(tienda, hoy, [
        alerta('a1', itemCoco),
        alerta('a2', itemPlatano),
      ]);
      await alertas.reemplazar(tienda, hoy, [alerta('a3', itemCoco)]);

      final leidas = await alertas.listarPorFecha(tienda, hoy);
      expect(leidas.map((a) => a.getId()), ['a3']);
      expect(
        await base.select(base.alertasReabastecimiento).get(),
        hasLength(1),
      );
    });

    test(
      'reemplazar anota los borrados y las inserciones en la cola',
      () async {
        await alertas.reemplazar(tienda, hoy, [alerta('a1', itemCoco)]);
        await alertas.reemplazar(tienda, hoy, [alerta('a2', itemCoco)]);

        final anotadas = [
          for (final f in await cola()) '${f.operacion} ${f.registroId}',
        ];
        expect(anotadas, ['INSERTAR a1', 'ELIMINAR a1', 'INSERTAR a2']);
        expect(
          (await cola()).every(
            (f) => f.tabla == 'alertas_reabastecimiento' && f.tiendaId == 't1',
          ),
          isTrue,
        );
      },
    );

    test('no toca las de otro día ni las de otra tienda', () async {
      final ayer = DateTime(2026, 11, 14);
      await alertas.reemplazar(tienda, ayer, [alerta('a0', itemCoco)]);
      await alertas.reemplazar(otraTienda, hoy, [alerta('b1', itemCoco)]);
      await alertas.reemplazar(tienda, hoy, [alerta('a1', itemCoco)]);
      await alertas.reemplazar(tienda, hoy, const []);

      expect(await alertas.listarPorFecha(tienda, hoy), isEmpty);
      expect(
        (await alertas.listarPorFecha(tienda, ayer)).map((a) => a.getId()),
        ['a0'],
      );
      expect(
        (await alertas.listarPorFecha(otraTienda, hoy)).map((a) => a.getId()),
        ['b1'],
      );
    });

    test('la hora de la fecha no importa: cuenta el día local', () async {
      await alertas.reemplazar(tienda, DateTime(2026, 11, 15, 23, 50), [
        alerta('a1', itemCoco),
      ]);

      expect(
        await alertas.listarPorFecha(tienda, DateTime(2026, 11, 15, 6)),
        hasLength(1),
      );
    });

    test('lista de menor a mayor cobertura', () async {
      await alertas.reemplazar(tienda, hoy, [
        alerta('a2', itemPlatano, dias: '2'),
        alerta('a1', itemCoco, dias: '0.87'),
      ]);

      final leidas = await alertas.listarPorFecha(tienda, hoy);
      expect(leidas.map((a) => a.getId()), ['a1', 'a2']);
    });
  });

  group('VentaPerdidaRepositorioDrift (solo lectura, DI-25)', () {
    Future<void> perdida(
      String id,
      Tienda deTienda,
      Producto producto,
      DateTime fecha,
    ) => base
        .into(base.ventasPerdidas)
        .insert(
          VentasPerdidasCompanion.insert(
            id: id,
            tiendaId: deTienda.getId(),
            productoId: producto.getId(),
            fecha: fecha,
          ),
        );

    final desde = DateTime.utc(2026, 10, 16);
    final hasta = DateTime.utc(2026, 11, 15);

    test('empiezan vacías', () async {
      expect(await perdidas.buscarPorPeriodo(tienda, desde, hasta), isEmpty);
      expect(await perdidas.listarPorProducto(coco, desde, hasta), isEmpty);
    });

    test('buscarPorPeriodo trae las de la tienda en [desde, hasta)', () async {
      await perdida('v1', tienda, coco, DateTime.utc(2026, 11, 3, 10));
      await perdida('v2', tienda, platano, DateTime.utc(2026, 11, 10, 9));
      await perdida('v3', tienda, coco, hasta);
      await perdida('v4', tienda, coco, DateTime.utc(2026, 10, 15, 23));
      await perdida('v5', otraTienda, coco, DateTime.utc(2026, 11, 3));

      final encontradas = await perdidas.buscarPorPeriodo(tienda, desde, hasta);
      expect(encontradas.map((v) => v.getId()), ['v2', 'v1']);
      expect(encontradas.last.getProducto().getNombre(), 'Coco');
      expect(encontradas.last.getFecha(), DateTime.utc(2026, 11, 3, 10));
    });

    test('listarPorProducto trae solo las del producto', () async {
      await perdida('v1', tienda, coco, DateTime.utc(2026, 11, 3));
      await perdida('v2', tienda, platano, DateTime.utc(2026, 11, 4));
      await perdida('v3', tienda, coco, DateTime.utc(2026, 11, 5));

      final encontradas = await perdidas.listarPorProducto(coco, desde, hasta);
      expect(encontradas.map((v) => v.getId()), ['v3', 'v1']);
    });
  });
}
