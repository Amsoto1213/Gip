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
}
