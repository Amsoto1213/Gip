import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/helpers/normalizar_texto.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');

  late BaseLocalDrift base;
  late ProductoRepositorioDrift productos;
  late InventarioRepositorioDrift items;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    productos = ProductoRepositorioDrift(base);
    items = InventarioRepositorioDrift(base);
  });
  tearDown(() => base.close());

  Producto producto(
    String id,
    String codigo,
    String nombre, {
    Decimal? compra,
  }) => Producto(
    id,
    codigo,
    nombre,
    UnidadMedida.kilogramo,
    compra,
    Decimal.parse('3500.50'),
  );

  Future<List<EntradaCola>> cola() => base.select(base.colaPendientes).get();

  group('normalizarTexto', () {
    test('quita tildes, mayúsculas y espacios de sobra; conserva la ñ', () {
      expect(normalizarTexto('  Café  ÁRABE Ñame '), 'cafe arabe ñame');
      expect(normalizarTexto('Pingüino'), 'pinguino');
    });
  });

  group('ProductoRepositorioDrift', () {
    test('guarda y lee el producto con decimales, nulos y fecha UTC', () async {
      final p = producto('p1', 'GAL-6', 'Galletas', compra: null)
        ..setActualizadoEn(DateTime.utc(2026, 11, 14, 10));
      await productos.guardar(tienda, p);

      final leido = (await productos.buscarPorId(tienda, 'p1'))!;
      expect(leido.getCodigo(), 'GAL-6');
      expect(leido.getNombre(), 'Galletas');
      expect(leido.getUnidadMedida(), UnidadMedida.kilogramo);
      expect(leido.getPrecioCompra(), isNull);
      expect(leido.getPrecioVenta(), Decimal.parse('3500.50'));
      expect(leido.getActualizadoEn(), DateTime.utc(2026, 11, 14, 10));
      expect(leido.getActualizadoEn().isUtc, isTrue);
      expect(leido.getCodigos(), isEmpty);
    });

    test('guarda la unidad en mayúsculas, como el enum de Supabase', () async {
      await productos.guardar(tienda, producto('p1', 'A', 'Arroz'));
      final crudo = await base
          .customSelect('SELECT unidad_medida FROM productos')
          .getSingle();
      expect(crudo.read<String>('unidad_medida'), 'KILOGRAMO');
    });

    test(
      'guardar dos veces actualiza y anota INSERTAR y luego ACTUALIZAR',
      () async {
        final p = producto('p1', 'GAL-6', 'Galletas');
        await productos.guardar(tienda, p);
        p.setNombre('Galletas de coco');
        await productos.guardar(tienda, p);

        expect(
          (await productos.listar(tienda)).single.getNombre(),
          'Galletas de coco',
        );
        final entradas = await cola();
        expect(entradas.map((e) => e.operacion), ['INSERTAR', 'ACTUALIZAR']);
        expect(entradas.every((e) => e.tabla == 'productos'), isTrue);
        expect(entradas.every((e) => e.registroId == 'p1'), isTrue);
        expect(entradas.every((e) => e.tiendaId == 't1'), isTrue);
      },
    );

    test('buscarPorCodigo distingue la tienda', () async {
      await productos.guardar(tienda, producto('p1', 'GAL-6', 'Galletas'));

      expect((await productos.buscarPorCodigo(tienda, 'GAL-6'))?.getId(), 'p1');
      expect(await productos.buscarPorCodigo(otraTienda, 'GAL-6'), isNull);
      expect(await productos.buscarPorCodigo(tienda, 'OTRO'), isNull);
    });

    test('buscarPorId y listar no ven productos de otra tienda', () async {
      await productos.guardar(tienda, producto('p1', 'A', 'Arroz'));
      await productos.guardar(otraTienda, producto('p2', 'B', 'Bocadillo'));

      expect(await productos.buscarPorId(otraTienda, 'p1'), isNull);
      expect((await productos.listar(tienda)).map((p) => p.getId()), ['p1']);
    });

    test(
      'listar ordena por nombre sin importar tildes ni mayúsculas',
      () async {
        await productos.guardar(tienda, producto('p1', 'A', 'zanahoria'));
        await productos.guardar(tienda, producto('p2', 'B', 'Ácido bórico'));
        await productos.guardar(tienda, producto('p3', 'C', 'Bocadillo'));

        expect((await productos.listar(tienda)).map((p) => p.getNombre()), [
          'Ácido bórico',
          'Bocadillo',
          'zanahoria',
        ]);
      },
    );

    test(
      'buscarPorNombre ignora tildes y mayúsculas y escapa comodines',
      () async {
        await productos.guardar(
          tienda,
          producto('p1', 'A', 'Café Águila 500 g'),
        );
        await productos.guardar(
          tienda,
          producto('p2', 'B', 'Leche 100% entera'),
        );

        expect(
          (await productos.buscarPorNombre(
            tienda,
            'AGUILA',
          )).map((p) => p.getId()),
          ['p1'],
        );
        expect(
          (await productos.buscarPorNombre(
            tienda,
            '100%',
          )).map((p) => p.getId()),
          ['p2'],
        );
        expect(await productos.buscarPorNombre(tienda, '_'), isEmpty);
        expect(await productos.buscarPorNombre(otraTienda, 'cafe'), isEmpty);
      },
    );
  });

  group('InventarioRepositorioDrift', () {
    test('guarda el ítem y lo lee con su producto y stock', () async {
      final p = producto('p1', 'A', 'Arroz');
      await productos.guardar(tienda, p);
      await items.guardarItem(tienda, ItemInventario('i1', p, Decimal.zero));

      final item = (await items.buscarItem(tienda, p))!;
      expect(item.getId(), 'i1');
      expect(item.getStockActual(), Decimal.zero);
      expect(await items.buscarItem(otraTienda, p), isNull);

      final entrada = (await cola()).last;
      expect(entrada.tabla, 'items_inventario');
      expect(entrada.registroId, 'i1');
      expect(entrada.operacion, 'INSERTAR');
    });

    test('listarItems trae el producto y ordena por nombre', () async {
      final zanahoria = producto('p1', 'A', 'Zanahoria');
      final arroz = producto('p2', 'B', 'arroz');
      for (final p in [zanahoria, arroz]) {
        await productos.guardar(tienda, p);
      }
      await items.guardarItem(
        tienda,
        ItemInventario('i1', zanahoria, Decimal.parse('2.5')),
      );
      await items.guardarItem(tienda, ItemInventario('i2', arroz, Decimal.one));

      final lista = await items.listarItems(tienda);
      expect(lista.map((i) => i.getProducto().getNombre()), [
        'arroz',
        'Zanahoria',
      ]);
      expect(lista.last.getStockActual(), Decimal.parse('2.5'));
      expect(await items.listarItems(otraTienda), isEmpty);
    });

    test('un producto tiene un solo ítem por tienda', () async {
      final p = producto('p1', 'A', 'Arroz');
      await productos.guardar(tienda, p);
      await items.guardarItem(tienda, ItemInventario('i1', p, Decimal.zero));

      await expectLater(
        items.guardarItem(tienda, ItemInventario('i2', p, Decimal.zero)),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('con UnidadTrabajoDrift', () {
    test(
      'si falla el ítem, no queda ni el producto ni su entrada en la cola',
      () async {
        final unidad = UnidadTrabajoDrift(base);
        final p = producto('p1', 'A', 'Arroz');

        await expectLater(
          unidad.ejecutar(() async {
            await productos.guardar(tienda, p);
            await items.guardarItem(
              tienda,
              ItemInventario('i1', p, Decimal.zero),
            );
            throw StateError('falla');
          }),
          throwsStateError,
        );

        expect(await productos.listar(tienda), isEmpty);
        expect(await items.listarItems(tienda), isEmpty);
        expect(await cola(), isEmpty);
      },
    );
  });

  group('migración', () {
    test('una base en versión 1 sube a 2 y crea productos e ítems', () async {
      await base.close();
      base = BaseLocalDrift(
        NativeDatabase.memory(
          setup: (db) {
            db.execute(
              'CREATE TABLE cola_pendientes (id TEXT NOT NULL PRIMARY KEY, '
              'tienda_id TEXT NOT NULL, tabla TEXT NOT NULL, '
              'registro_id TEXT NOT NULL, operacion TEXT NOT NULL, '
              'intentos INTEGER NOT NULL DEFAULT 0, creado_en TEXT NOT NULL)',
            );
            db.execute('PRAGMA user_version = 1');
          },
        ),
      );
      productos = ProductoRepositorioDrift(base);
      items = InventarioRepositorioDrift(base);

      final p = producto('p1', 'A', 'Arroz');
      await productos.guardar(tienda, p);
      await items.guardarItem(tienda, ItemInventario('i1', p, Decimal.zero));

      expect(await items.listarItems(tienda), hasLength(1));
      final version = await base
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 2);
    });
  });
}
