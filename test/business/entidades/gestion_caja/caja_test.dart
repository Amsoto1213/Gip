import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);
  final hoy = DateTime(2026, 11, 14);

  MovimientoCaja mov(
    String valor,
    TipoMovimientoCaja tipo, [
    ClasificacionMovimiento c = ClasificacionMovimiento.negocio,
  ]) => MovimientoCaja('m$valor', d(valor), 'x', c, tipo, hoy);

  test('calcularSaldoEsperado suma ingresos y resta egresos', () {
    final caja = Caja('t_2026-11-14', hoy)
      ..registrarMovimiento(mov('32000', TipoMovimientoCaja.ingreso))
      ..registrarMovimiento(mov('12000', TipoMovimientoCaja.ingreso))
      ..registrarMovimiento(
        mov(
          '5000',
          TipoMovimientoCaja.egreso,
          ClasificacionMovimiento.personal,
        ),
      );
    expect(caja.calcularSaldoEsperado(), d('39000'));
    expect(caja.getMovimientos(), hasLength(3));
  });

  test('una caja nueva está abierta y con saldo cero', () {
    final caja = Caja('t_2026-11-14', hoy);
    expect(caja.isCerrada(), isFalse);
    expect(caja.calcularSaldoEsperado(), Decimal.zero);
  });

  test('esIngreso y esDelNegocio', () {
    final ingreso = mov('1', TipoMovimientoCaja.ingreso);
    final retiro = mov(
      '2',
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.personal,
    );
    expect(ingreso.esIngreso(), isTrue);
    expect(ingreso.esDelNegocio(), isTrue);
    expect(retiro.esIngreso(), isFalse);
    expect(retiro.esDelNegocio(), isFalse);
  });
}
