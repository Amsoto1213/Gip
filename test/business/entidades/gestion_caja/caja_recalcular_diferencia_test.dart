import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

/// Caja.recalcularDiferencia (CUS-22, DA-66, DI-45): llegó un movimiento a una
/// caja que ya estaba cerrada.
void main() {
  Decimal d(String v) => Decimal.parse(v);
  final dia = DateTime(2026, 11, 14);
  final cierre = DateTime.utc(2026, 11, 14, 23);

  MovimientoCaja mov(String id, String valor, TipoMovimientoCaja tipo) =>
      MovimientoCaja(
        id,
        d(valor),
        'x',
        ClasificacionMovimiento.negocio,
        tipo,
        dia,
      );

  Caja cerrada({
    required List<MovimientoCaja> movimientos,
    required String contado,
    required String diferencia,
    String base = '0',
  }) => Caja(
    't_2026-11-14',
    dia,
    baseApertura: d(base),
    movimientos: movimientos,
    efectivoContado: d(contado),
    diferencia: d(diferencia),
    fechaCierre: cierre,
  );

  test('un ingreso que llegó tarde baja la diferencia: faltante', () {
    // Al cerrar: esperado 30000, contado 30000, diferencia 0. Después llegó
    // un ingreso de 2000 que no estaba en el efectivo contado.
    final caja = cerrada(
      movimientos: [
        mov('m1', '30000', TipoMovimientoCaja.ingreso),
        mov('m2', '2000', TipoMovimientoCaja.ingreso),
      ],
      contado: '30000',
      diferencia: '0',
    );

    expect(caja.recalcularDiferencia(), d('-2000'));
    expect(caja.getDiferencia(), d('-2000'));
  });

  test('un egreso que llegó tarde sube la diferencia: sobrante', () {
    final caja = cerrada(
      movimientos: [
        mov('m1', '30000', TipoMovimientoCaja.ingreso),
        mov('m2', '5000', TipoMovimientoCaja.egreso),
      ],
      contado: '30000',
      diferencia: '0',
    );

    expect(caja.recalcularDiferencia(), d('5000'));
  });

  test('incluye la base de apertura', () {
    final caja = cerrada(
      base: '10000',
      movimientos: [mov('m1', '5000', TipoMovimientoCaja.ingreso)],
      contado: '15000',
      diferencia: '0',
    );

    expect(caja.recalcularDiferencia(), Decimal.zero);
  });

  test('no cambia el efectivo contado ni la fecha del cierre, y sigue '
      'cerrada', () {
    final caja = cerrada(
      movimientos: [mov('m1', '1000', TipoMovimientoCaja.ingreso)],
      contado: '500',
      diferencia: '-500',
    );

    caja.recalcularDiferencia();

    expect(caja.getEfectivoContado(), d('500'));
    expect(caja.getFechaCierre(), cierre);
    expect(caja.isCerrada(), isTrue);
  });

  test('recalcular dos veces da lo mismo', () {
    final caja = cerrada(
      movimientos: [mov('m1', '1000', TipoMovimientoCaja.ingreso)],
      contado: '400',
      diferencia: '0',
    );

    caja.recalcularDiferencia();

    expect(caja.recalcularDiferencia(), d('-600'));
  });

  test('una caja abierta no tiene diferencia que recalcular', () {
    final caja = Caja('t_2026-11-14', dia);

    expect(caja.recalcularDiferencia, throwsA(isA<ExcepcionCajaNoCerrada>()));
  });
}
