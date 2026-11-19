import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';

/// Fiado.recalcularSaldo (CUS-22, DA-48, DI-45).
void main() {
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15);
  final cliente = Cliente('c1', 'María Pérez', '');

  Abono abono(String id, String monto, {bool anulado = false}) =>
      Abono(id, d(monto), fecha, MedioPago.efectivo, null, anulado: anulado);

  Fiado fiado(
    String monto,
    List<Abono> abonos, {
    EstadoFiado estado = EstadoFiado.pendiente,
    String saldo = '0',
  }) =>
      Fiado.guardado('f1', d(monto), fecha, cliente, d(saldo), estado, abonos);

  test('saldo = monto inicial menos los abonos', () {
    final f = fiado('20000', [abono('a1', '5000'), abono('a2', '3000')]);

    expect(f.recalcularSaldo(), d('12000'));
    expect(f.getSaldoPendiente(), d('12000'));
    expect(f.getEstado(), EstadoFiado.pendiente);
  });

  test('los abonos anulados no cuentan', () {
    final f = fiado('20000', [
      abono('a1', '5000'),
      abono('a2', '9000', anulado: true),
    ]);

    expect(f.recalcularSaldo(), d('15000'));
  });

  test('sin abonos, el saldo es el monto inicial', () {
    expect(fiado('8400', const []).recalcularSaldo(), d('8400'));
  });

  test('saldo cero: queda SALDADO', () {
    final f = fiado('8000', [abono('a1', '8000')]);

    f.recalcularSaldo();

    expect(f.getSaldoPendiente(), Decimal.zero);
    expect(f.getEstado(), EstadoFiado.saldado);
  });

  test('abonos de más: el saldo queda negativo y el estado SALDADO', () {
    // Dos equipos sin internet recibieron cada uno un abono de 8000.
    final f = fiado('10000', [abono('a1', '8000'), abono('a2', '8000')]);

    expect(f.recalcularSaldo(), d('-6000'));
    expect(f.getEstado(), EstadoFiado.saldado);
  });

  test('si se anula un abono y el saldo vuelve a ser positivo, pasa a '
      'PENDIENTE', () {
    final a2 = abono('a2', '8000');
    final f = fiado('10000', [abono('a1', '8000'), a2]);
    f.recalcularSaldo();

    a2.anular();
    f.recalcularSaldo();

    expect(f.getSaldoPendiente(), d('2000'));
    expect(f.getEstado(), EstadoFiado.pendiente);
  });

  test('anular el abono que sobra deja el saldo en cero', () {
    final a2 = abono('a2', '2000');
    final f = fiado('10000', [abono('a1', '8000'), abono('a3', '2000'), a2]);
    f.recalcularSaldo();
    expect(f.getSaldoPendiente(), d('-2000'));

    a2.anular();
    f.recalcularSaldo();

    expect(f.getSaldoPendiente(), Decimal.zero);
    expect(f.getEstado(), EstadoFiado.saldado);
  });

  test('un fiado anulado conserva su estado y su saldo en cero', () {
    final f = fiado('8000', const [], estado: EstadoFiado.anulado);

    expect(f.recalcularSaldo(), Decimal.zero);
    expect(f.getEstado(), EstadoFiado.anulado);
  });

  test('recalcular dos veces da lo mismo', () {
    final f = fiado('20000', [abono('a1', '5000')]);

    f.recalcularSaldo();

    expect(f.recalcularSaldo(), d('15000'));
  });
}
