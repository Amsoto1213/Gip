import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15);

  Abono abono(String monto, {MedioPago medio = MedioPago.efectivo}) =>
      Abono('a${monto}_${medio.name}', d(monto), fecha, medio, null);

  Fiado fiado() => Fiado('f1', d('25000'), fecha, Cliente('c1', 'María', ''));

  group('Abono', () {
    test('solo el efectivo entra a la caja', () {
      expect(abono('100').esEfectivo(), isTrue);
      expect(abono('100', medio: MedioPago.nequi).esEfectivo(), isFalse);
    });

    test('anular lo marca y no se puede anular dos veces', () {
      final a = abono('100');
      expect(a.isAnulado(), isFalse);
      a.anular();
      expect(a.isAnulado(), isTrue);
      expect(a.anular, throwsStateError);
    });
  });

  group('Fiado.registrarAbono', () {
    test('abono parcial baja el saldo y sigue PENDIENTE', () {
      final f = fiado();
      final a = abono('12500');
      expect(f.registrarAbono(a), same(a));
      expect(f.getSaldoPendiente(), d('12500'));
      expect(f.getEstado(), EstadoFiado.pendiente);
      expect(f.getAbonos(), [a]);
    });

    test('abono que llega a cero pasa a SALDADO (RN-05)', () {
      final f = fiado()..registrarAbono(abono('10000'));
      f.registrarAbono(abono('15000'));
      expect(f.getSaldoPendiente(), Decimal.zero);
      expect(f.getEstado(), EstadoFiado.saldado);
    });

    for (final monto in ['0', '-5', '25000.01']) {
      test('monto $monto no es válido y no cambia el fiado', () {
        final f = fiado();
        expect(
          () => f.registrarAbono(abono(monto)),
          throwsA(isA<ExcepcionMontoAbonoNoValido>()),
        );
        expect(f.getSaldoPendiente(), d('25000'));
        expect(f.getAbonos(), isEmpty);
      });
    }

    test('un fiado saldado ya no recibe abonos', () {
      final f = fiado()..registrarAbono(abono('25000'));
      expect(
        () => f.registrarAbono(abono('1')),
        throwsA(isA<ExcepcionMontoAbonoNoValido>()),
      );
    });

    test('Fiado.guardado trae sus abonos y el cliente suma el saldo', () {
      final cliente = Cliente('c1', 'María', '');
      final f = Fiado.guardado(
        'f2',
        d('20000'),
        fecha,
        cliente,
        d('5000'),
        EstadoFiado.pendiente,
        [abono('15000')],
      );
      cliente.agregarFiado(f);
      expect(f.getAbonos(), hasLength(1));
      expect(cliente.calcularSaldoPendiente(), d('5000'));
    });
  });
}
