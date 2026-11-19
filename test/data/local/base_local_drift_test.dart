import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';

void main() {
  group('ConversorDecimal', () {
    const conversor = ConversorDecimal();

    test('ida y vuelta sin perder decimales', () {
      for (final texto in ['0', '13400', '0.125', '-2.5', '1284000.75']) {
        final valor = Decimal.parse(texto);
        expect(conversor.fromSql(conversor.toSql(valor)), valor);
      }
    });

    test('guarda el número como texto plano', () {
      expect(conversor.toSql(Decimal.parse('0.125')), '0.125');
    });
  });

  group('cola_pendientes', () {
    late BaseLocalDrift base;

    setUp(() => base = BaseLocalDrift(NativeDatabase.memory()));
    tearDown(() => base.close());

    test('una fecha local se guarda y se lee en UTC', () async {
      final local = DateTime(2026, 11, 14, 18, 40, 5);
      await base
          .into(base.colaPendientes)
          .insert(
            ColaPendientesCompanion.insert(
              id: 'e1',
              tiendaId: 't1',
              tabla: 'productos',
              registroId: 'p1',
              operacion: 'INSERTAR',
              creadoEn: local,
            ),
          );

      final leida = await base.select(base.colaPendientes).getSingle();
      expect(leida.creadoEn.isUtc, isTrue);
      expect(leida.creadoEn, local.toUtc());
      expect(leida.intentos, 0);

      final crudo = await base
          .customSelect('SELECT creado_en FROM cola_pendientes')
          .getSingle();
      expect(crudo.read<String>('creado_en'), endsWith('Z'));
    });
  });

  group('migración', () {
    late Directory carpeta;

    setUp(() => carpeta = Directory.systemTemp.createTempSync('gip_migracion'));
    tearDown(() => carpeta.deleteSync(recursive: true));

    Future<List<String>> tablas(BaseLocalDrift base) async =>
        (await base
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
                )
                .get())
            .map((f) => f.read<String>('name'))
            .toList();

    /// Quita lo que agregó la versión 13 (CUS-14, DI-38).
    Future<void> bajarDeLaVersion13(BaseLocalDrift base) async {
      await base.customStatement('ALTER TABLE cajas DROP COLUMN base_apertura');
    }

    /// Quita lo que agregó la versión 12 (CUS-14), y antes la 13.
    Future<void> bajarDeLaVersion12(BaseLocalDrift base) async {
      await bajarDeLaVersion13(base);
      for (final c in [
        'cerrada',
        'efectivo_contado',
        'diferencia',
        'fecha_cierre',
      ]) {
        await base.customStatement('ALTER TABLE cajas DROP COLUMN $c');
      }
    }

    /// Quita lo que agregó la versión 11 (CUS-17), y antes la 12.
    Future<void> bajarDeLaVersion11(BaseLocalDrift base) async {
      await bajarDeLaVersion12(base);
      await base.customStatement('DROP TABLE codigos_producto');
    }

    /// Quita lo que agregó la versión 10 (CUS-21), y antes la 11.
    Future<void> bajarDeLaVersion10(BaseLocalDrift base) async {
      await bajarDeLaVersion11(base);
      await base.customStatement(
        'ALTER TABLE clientes DROP COLUMN eliminado_en',
      );
    }

    /// Quita lo que agregó la versión 9 (CUS-08), y antes la 10.
    Future<void> bajarDeLaVersion9(BaseLocalDrift base) async {
      await bajarDeLaVersion10(base);
      await base.customStatement('DROP TABLE abonos');
    }

    /// Quita lo que agregó la versión 8 (CUS-07).

    Future<void> bajarDeLaVersion8(BaseLocalDrift base) async {
      for (final t in ['fiados', 'clientes']) {
        await base.customStatement('DROP TABLE $t');
      }
    }

    /// Quita lo que agregó la versión 7 (CUS-24 y CUS-05).
    Future<void> bajarDeLaVersion7(BaseLocalDrift base) async {
      for (final t in ['alertas_reabastecimiento', 'ventas_perdidas']) {
        await base.customStatement('DROP TABLE $t');
      }
    }

    /// Quita lo que agregó la versión 4 (CUS-02).
    Future<void> bajarDeLaVersion4(BaseLocalDrift base) async {
      for (final t in ['formas_pago', 'ventas', 'movimientos_caja', 'cajas']) {
        await base.customStatement('DROP TABLE $t');
      }
    }

    test('de la versión 2 a la actual crea movimientos_inventario', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      // Deja la base como estaba en la versión 2 (CUS-18).
      final v2 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion9(v2);
      await bajarDeLaVersion8(v2);
      await bajarDeLaVersion4(v2);
      await v2.customStatement('DROP TABLE movimientos_inventario');
      await bajarDeLaVersion7(v2);
      await v2.customStatement('PRAGMA user_version = 2');
      expect(await tablas(v2), isNot(contains('movimientos_inventario')));
      await v2.close();

      final actual = BaseLocalDrift(NativeDatabase(archivo));
      expect(actual.schemaVersion, 13);
      expect(
        await tablas(actual),
        containsAll([
          'codigos_producto',
          'movimientos_inventario',
          'movimientos_inventario_tienda_idx',
          'movimientos_inventario_item_tipo_fecha_idx',
          'productos',
          'items_inventario',
          'ventas',
          'alertas_reabastecimiento',
          'ventas_perdidas',
          'clientes',
          'fiados',
          'abonos',
        ]),
      );
      final version = await actual
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 13);
      await actual.close();
    });

    test('de la versión 3 a la 4 crea caja y ventas y agrega las columnas de '
        'SALIDA_VENTA', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      // Deja la base como estaba en la versión 3 (CUS-01).
      final v3 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion9(v3);
      await bajarDeLaVersion8(v3);
      await bajarDeLaVersion4(v3);
      await v3.customStatement('DROP TABLE movimientos_inventario');
      await v3.customStatement(
        'CREATE TABLE movimientos_inventario (id TEXT NOT NULL, '
        'tienda_id TEXT NOT NULL, item_id TEXT NOT NULL REFERENCES '
        'items_inventario (id), tipo TEXT NOT NULL, cantidad TEXT NOT NULL, '
        'fecha TEXT NOT NULL, estado TEXT NOT NULL, costo_unitario TEXT NULL, '
        'numero_factura TEXT NULL, PRIMARY KEY (id))',
      );
      await bajarDeLaVersion7(v3);
      await v3.customStatement('PRAGMA user_version = 3');
      await v3.close();

      final v4 = BaseLocalDrift(NativeDatabase(archivo));
      expect(
        await tablas(v4),
        containsAll([
          'cajas',
          'cajas_tienda_idx',
          'movimientos_caja',
          'movimientos_caja_tienda_idx',
          'movimientos_caja_caja_idx',
          'ventas',
          'ventas_tienda_fecha_idx',
          'formas_pago',
          'formas_pago_tienda_idx',
          'formas_pago_venta_idx',
        ]),
      );
      final columnas =
          (await v4
                  .customSelect('PRAGMA table_info(movimientos_inventario)')
                  .get())
              .map((f) => f.read<String>('name'));
      expect(
        columnas,
        containsAll([
          'venta_id',
          'precio_unitario',
          'motivo',
          'cantidad_contada',
        ]),
      );
      await v4.close();
    });
    test(
      'de la versión 4 a la 5 agrega motivo (MERMA) sin perder filas',
      () async {
        final archivo = File('${carpeta.path}/gip.sqlite');

        // Deja la base como estaba en la versión 4 (CUS-02), con una entrada.
        final v4 = BaseLocalDrift(NativeDatabase(archivo));
        await v4.customStatement(
          'ALTER TABLE movimientos_inventario DROP COLUMN motivo',
        );
        await v4.customStatement(
          'ALTER TABLE movimientos_inventario DROP COLUMN cantidad_contada',
        );
        await v4.customStatement('PRAGMA foreign_keys = OFF');
        await v4.customStatement(
          "INSERT INTO movimientos_inventario (id, tienda_id, item_id, tipo, "
          "cantidad, fecha, estado, costo_unitario) VALUES ('e1', 't1', 'i1', "
          "'ENTRADA', '24', '2026-11-14T10:00:00.000Z', 'VIGENTE', '8600')",
        );
        await bajarDeLaVersion9(v4);
        await bajarDeLaVersion8(v4);
        await bajarDeLaVersion7(v4);
        await v4.customStatement('PRAGMA user_version = 4');
        await v4.close();

        final v5 = BaseLocalDrift(NativeDatabase(archivo));
        final columnas =
            (await v5
                    .customSelect('PRAGMA table_info(movimientos_inventario)')
                    .get())
                .map((f) => f.read<String>('name'));
        expect(columnas, contains('motivo'));
        final fila = await v5
            .customSelect('SELECT id, motivo FROM movimientos_inventario')
            .getSingle();
        expect(fila.read<String>('id'), 'e1');
        expect(fila.read<String?>('motivo'), isNull);
        await v5.close();
      },
    );
    test('de la versión 5 a la 6 agrega cantidad_contada (AJUSTE_CONTEO) sin '
        'perder filas', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      // Deja la base como estaba en la versión 5 (CUS-03), con una entrada.
      final v5 = BaseLocalDrift(NativeDatabase(archivo));
      await v5.customStatement(
        'ALTER TABLE movimientos_inventario DROP COLUMN cantidad_contada',
      );
      await v5.customStatement('PRAGMA foreign_keys = OFF');
      await v5.customStatement(
        "INSERT INTO movimientos_inventario (id, tienda_id, item_id, tipo, "
        "cantidad, fecha, estado, costo_unitario) VALUES ('e1', 't1', 'i1', "
        "'ENTRADA', '24', '2026-11-14T10:00:00.000Z', 'VIGENTE', '8600')",
      );
      await bajarDeLaVersion9(v5);
      await bajarDeLaVersion8(v5);
      await bajarDeLaVersion7(v5);
      await v5.customStatement('PRAGMA user_version = 5');
      await v5.close();

      final v6 = BaseLocalDrift(NativeDatabase(archivo));
      final fila = await v6
          .customSelect(
            'SELECT id, cantidad_contada FROM movimientos_inventario',
          )
          .getSingle();
      expect(fila.read<String>('id'), 'e1');
      expect(fila.read<String?>('cantidad_contada'), isNull);
      await v6.close();
    });

    test('de la versión 6 a la 7 crea alertas_reabastecimiento y '
        'ventas_perdidas', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v6 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion9(v6);
      await bajarDeLaVersion8(v6);
      await bajarDeLaVersion7(v6);
      await v6.customStatement('PRAGMA user_version = 6');
      expect(await tablas(v6), isNot(contains('alertas_reabastecimiento')));
      await v6.close();

      final v7 = BaseLocalDrift(NativeDatabase(archivo));
      expect(
        await tablas(v7),
        containsAll([
          'alertas_reabastecimiento',
          'alertas_reabastecimiento_tienda_fecha_idx',
          'ventas_perdidas',
          'ventas_perdidas_tienda_fecha_idx',
          'ventas_perdidas_producto_fecha_idx',
        ]),
      );
      await v7.close();
    });

    test('de la versión 7 a la 8 crea clientes y fiados', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v7 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion9(v7);
      await bajarDeLaVersion8(v7);
      await v7.customStatement('PRAGMA user_version = 7');
      expect(await tablas(v7), isNot(contains('fiados')));
      await v7.close();

      final v8 = BaseLocalDrift(NativeDatabase(archivo));
      expect(
        await tablas(v8),
        containsAll([
          'clientes',
          'clientes_tienda_nombre_idx',
          'fiados',
          'fiados_tienda_idx',
          'fiados_cliente_idx',
        ]),
      );
      await v8.close();
    });

    test('de la versión 8 a la 9 crea abonos', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v8 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion9(v8);
      await v8.customStatement('PRAGMA user_version = 8');
      expect(await tablas(v8), isNot(contains('abonos')));
      await v8.close();

      final v9 = BaseLocalDrift(NativeDatabase(archivo));
      expect(
        await tablas(v9),
        containsAll(['abonos', 'abonos_tienda_idx', 'abonos_fiado_idx']),
      );
      await v9.close();
    });

    test('de la versión 9 a la 10 agrega eliminado_en a clientes sin perder '
        'filas', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v9 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion10(v9);
      await v9.customStatement(
        "INSERT INTO clientes (id, tienda_id, nombre, nombre_normalizado, "
        "telefono, actualizado_en) VALUES ('c1', 't1', 'Ana', 'ana', '300', "
        "'2026-11-14T10:00:00.000Z')",
      );
      await v9.customStatement('PRAGMA user_version = 9');
      await v9.close();

      final v10 = BaseLocalDrift(NativeDatabase(archivo));
      final columnas =
          (await v10.customSelect('PRAGMA table_info(clientes)').get()).map(
            (f) => f.read<String>('name'),
          );
      expect(columnas, contains('eliminado_en'));
      final filas = await v10.select(v10.clientes).get();
      expect(filas.single.nombre, 'Ana');
      expect(filas.single.eliminadoEn, isNull);
      await v10.close();
    });

    test('de la versión 10 a la 11 crea codigos_producto sin perder '
        'productos', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v10 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion11(v10);
      await v10.customStatement(
        "INSERT INTO productos (id, tienda_id, codigo, nombre, "
        "nombre_normalizado, unidad_medida, precio_venta, actualizado_en) "
        "VALUES ('p1', 't1', 'LEC-1', 'Leche', 'leche', 'UNIDAD', '4200', "
        "'2026-11-14T10:00:00.000Z')",
      );
      await v10.customStatement('PRAGMA user_version = 10');
      expect(await tablas(v10), isNot(contains('codigos_producto')));
      await v10.close();

      final v11 = BaseLocalDrift(NativeDatabase(archivo));
      expect(
        await tablas(v11),
        containsAll([
          'codigos_producto',
          'codigos_producto_tienda_valor_idx',
          'codigos_producto_producto_idx',
        ]),
      );
      expect((await v11.select(v11.productos).get()).single.nombre, 'Leche');
      expect(await v11.select(v11.codigosProducto).get(), isEmpty);
      await v11.close();
    });

    test('de la versión 11 a la 12 agrega el cierre a cajas sin perder '
        'cajas ni movimientos', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v11 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion12(v11);
      await v11.customStatement(
        "INSERT INTO cajas (id, tienda_id, fecha) "
        "VALUES ('t1_2026-11-14', 't1', '2026-11-14')",
      );
      await v11.customStatement(
        "INSERT INTO movimientos_caja (id, tienda_id, caja_id, tipo, "
        "clasificacion, valor, descripcion, fecha) VALUES ('m1', 't1', "
        "'t1_2026-11-14', 'INGRESO', 'NEGOCIO', '1000', 'Venta', "
        "'2026-11-14T10:00:00.000Z')",
      );
      await v11.customStatement('PRAGMA user_version = 11');
      await v11.close();

      final v12 = BaseLocalDrift(NativeDatabase(archivo));
      final caja = (await v12.select(v12.cajas).get()).single;
      expect(caja.id, 't1_2026-11-14');
      expect(caja.cerrada, isFalse);
      expect(caja.efectivoContado, isNull);
      expect(caja.diferencia, isNull);
      expect(caja.fechaCierre, isNull);
      expect(await v12.select(v12.movimientosCaja).get(), hasLength(1));
      await v12.close();
    });

    test('de la versión 12 a la 13 agrega base_apertura (en 0) sin perder '
        'cajas', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      final v12 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion13(v12);
      await v12.customStatement(
        "INSERT INTO cajas (id, tienda_id, fecha, cerrada) "
        "VALUES ('t1_2026-11-14', 't1', '2026-11-14', 0)",
      );
      await v12.customStatement('PRAGMA user_version = 12');
      await v12.close();

      final v13 = BaseLocalDrift(NativeDatabase(archivo));
      final caja = (await v13.select(v13.cajas).get()).single;
      expect(caja.id, 't1_2026-11-14');
      expect(caja.baseApertura, Decimal.zero);
      await v13.close();
    });
  });
}
