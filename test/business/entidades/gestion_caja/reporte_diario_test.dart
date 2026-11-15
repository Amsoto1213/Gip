import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';

/// ReporteDiario (CUS-10): el dinero de Nequi suma ventas y abonos (DA-63/64).
void main() {
  Decimal d(String v) => Decimal.parse(v);

  ReporteDiario reporte({String ventasNequi = '0', String abonosNequi = '0'}) =>
      ReporteDiario(
        DateTime(2026, 11, 14),
        d('100000'),
        d('20000'),
        d(ventasNequi),
        d('15000'),
        d(abonosNequi),
        d('50000'),
        d('0'),
        d('30000'),
        d('0'),
        false,
        false,
      );

  test('calcularDineroNequi suma ventas y abonos por Nequi', () {
    expect(
      reporte(ventasNequi: '30000', abonosNequi: '5000').calcularDineroNequi(),
      d('35000'),
    );
  });

  test('sin Nequi el dinero es cero', () {
    expect(reporte().calcularDineroNequi(), Decimal.zero);
  });

  test('expone los datos con los que se creó', () {
    final r = reporte(ventasNequi: '1');
    expect(r.getTotalVentas(), d('100000'));
    expect(r.getVentasFiadas(), d('20000'));
    expect(r.getAbonosRecibidos(), d('15000'));
    expect(r.getTotalEntradas(), d('50000'));
    expect(r.getUtilidad(), d('30000'));
    expect(r.isIncompleto(), isFalse);
    expect(r.isParcial(), isFalse);
  });
}
