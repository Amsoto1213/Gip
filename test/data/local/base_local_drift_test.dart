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
      await bajarDeLaVersion4(v2);
      await v2.customStatement('DROP TABLE movimientos_inventario');
      await v2.customStatement('PRAGMA user_version = 2');
      expect(await tablas(v2), isNot(contains('movimientos_inventario')));
      await v2.close();

      final actual = BaseLocalDrift(NativeDatabase(archivo));
      expect(actual.schemaVersion, 4);
      expect(
        await tablas(actual),
        containsAll([
          'movimientos_inventario',
          'movimientos_inventario_tienda_idx',
          'movimientos_inventario_item_tipo_fecha_idx',
          'productos',
          'items_inventario',
          'ventas',
        ]),
      );
      final version = await actual
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 4);
      await actual.close();
    });

    test('de la versión 3 a la 4 crea caja y ventas y agrega las columnas de '
        'SALIDA_VENTA', () async {
      final archivo = File('${carpeta.path}/gip.sqlite');

      // Deja la base como estaba en la versión 3 (CUS-01).
      final v3 = BaseLocalDrift(NativeDatabase(archivo));
      await bajarDeLaVersion4(v3);
      await v3.customStatement('DROP TABLE movimientos_inventario');
      await v3.customStatement(
        'CREATE TABLE movimientos_inventario (id TEXT NOT NULL, '
        'tienda_id TEXT NOT NULL, item_id TEXT NOT NULL REFERENCES '
        'items_inventario (id), tipo TEXT NOT NULL, cantidad TEXT NOT NULL, '
        'fecha TEXT NOT NULL, estado TEXT NOT NULL, costo_unitario TEXT NULL, '
        'numero_factura TEXT NULL, PRIMARY KEY (id))',
      );
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
      expect(columnas, containsAll(['venta_id', 'precio_unitario']));
      await v4.close();
    });
  });
}
