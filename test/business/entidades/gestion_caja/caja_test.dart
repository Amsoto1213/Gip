import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

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

  group('cerrar (CUS-14)', () {
    Caja cajaConSaldo318500() => Caja('t_2026-11-14', hoy)
      ..registrarMovimiento(mov('100000', TipoMovimientoCaja.ingreso))
      ..registrarMovimiento(mov('268000', TipoMovimientoCaja.ingreso))
      ..registrarMovimiento(mov('8500', TipoMovimientoCaja.ingreso))
      ..registrarMovimiento(mov('18000', TipoMovimientoCaja.egreso))
      ..registrarMovimiento(
        mov(
          '40000',
          TipoMovimientoCaja.egreso,
          ClasificacionMovimiento.personal,
        ),
      );

    test('una caja abierta no tiene datos de cierre', () {
      final caja = Caja('t_2026-11-14', hoy);
      expect(caja.getEfectivoContado(), isNull);
      expect(caja.getDiferencia(), isNull);
      expect(caja.getFechaCierre(), isNull);
    });

    test('con menos efectivo del esperado la diferencia es un faltante '
        '(negativa)', () {
      final caja = cajaConSaldo318500();
      expect(caja.calcularSaldoEsperado(), d('318500'));

      final diferencia = caja.cerrar(d('315000'));

      expect(diferencia, d('-3500'));
      expect(caja.getDiferencia(), d('-3500'));
      expect(caja.getEfectivoContado(), d('315000'));
      expect(caja.isCerrada(), isTrue);
    });

    test('con más efectivo del esperado la diferencia es un sobrante '
        '(positiva)', () {
      expect(cajaConSaldo318500().cerrar(d('320000')), d('1500'));
    });

    test('si cuadra, la diferencia es cero', () {
      final caja = cajaConSaldo318500();
      expect(caja.cerrar(d('318500')), Decimal.zero);
      expect(caja.isCerrada(), isTrue);
    });

    test('una caja sin movimientos se cierra con su saldo en cero', () {
      expect(Caja('t_2026-11-14', hoy).cerrar(d('2000')), d('2000'));
    });

    test('guarda la fecha del cierre en UTC', () {
      final antes = DateTime.now().toUtc();
      final caja = cajaConSaldo318500()..cerrar(d('318500'));
      final despues = DateTime.now().toUtc();

      final fecha = caja.getFechaCierre()!;
      expect(fecha.isUtc, isTrue);
      expect(fecha.isBefore(antes), isFalse);
      expect(fecha.isAfter(despues), isFalse);
    });

    test('rechaza un segundo cierre y no cambia el primero', () {
      final caja = cajaConSaldo318500()..cerrar(d('315000'));

      expect(
        () => caja.cerrar(d('318500')),
        throwsA(isA<ExcepcionCajaCerrada>()),
      );
      expect(caja.getDiferencia(), d('-3500'));
      expect(caja.getEfectivoContado(), d('315000'));
    });

    test('cerrada, rechaza nuevos movimientos', () {
      final caja = cajaConSaldo318500()..cerrar(d('318500'));

      expect(
        () => caja.registrarMovimiento(mov('1000', TipoMovimientoCaja.ingreso)),
        throwsA(isA<ExcepcionCajaCerrada>()),
      );
      expect(caja.calcularSaldoEsperado(), d('318500'));
    });

    test('una caja leída ya cerrada conserva su cierre', () {
      final fecha = DateTime.utc(2026, 11, 14, 23);
      final caja = Caja(
        't_2026-11-14',
        hoy,
        efectivoContado: d('315000'),
        diferencia: d('-3500'),
        fechaCierre: fecha,
      );

      expect(caja.isCerrada(), isTrue);
      expect(caja.getDiferencia(), d('-3500'));
      expect(caja.getFechaCierre(), fecha);
      expect(() => caja.cerrar(d('1')), throwsA(isA<ExcepcionCajaCerrada>()));
    });
  });

  group('base de apertura (DI-38)', () {
    test('sin base, abre en cero', () {
      expect(Caja('t_2026-11-14', hoy).getBaseApertura(), Decimal.zero);
    });

    test('el saldo esperado suma la base a los movimientos', () {
      final caja = Caja('t_2026-11-14', hoy, baseApertura: d('100000'))
        ..registrarMovimiento(mov('268000', TipoMovimientoCaja.ingreso))
        ..registrarMovimiento(mov('18000', TipoMovimientoCaja.egreso));

      expect(caja.getBaseApertura(), d('100000'));
      expect(caja.calcularSaldoEsperado(), d('350000'));
    });

    test('la diferencia del cierre cuenta la base', () {
      final caja = Caja('t_2026-11-14', hoy, baseApertura: d('100000'))
        ..registrarMovimiento(mov('50000', TipoMovimientoCaja.ingreso));

      expect(caja.cerrar(d('148000')), d('-2000'));
    });
  });

  group('calcularDesglose (DI-38)', () {
    MovimientoCaja movc(
      String id,
      String valor,
      TipoMovimientoCaja tipo,
      ClasificacionMovimiento c,
    ) => MovimientoCaja(id, d(valor), 'x', c, tipo, hoy);

    test('separa la base y cada clase de movimiento', () {
      final caja = Caja('t_2026-11-14', hoy, baseApertura: d('100000'))
        ..registrarMovimiento(
          movc(
            '1',
            '268000',
            TipoMovimientoCaja.ingreso,
            ClasificacionMovimiento.negocio,
          ),
        )
        ..registrarMovimiento(
          movc(
            '2',
            '8500',
            TipoMovimientoCaja.ingreso,
            ClasificacionMovimiento.negocio,
          ),
        )
        ..registrarMovimiento(
          movc(
            '3',
            '12000',
            TipoMovimientoCaja.egreso,
            ClasificacionMovimiento.negocio,
          ),
        )
        ..registrarMovimiento(
          movc(
            '4',
            '6000',
            TipoMovimientoCaja.egreso,
            ClasificacionMovimiento.negocio,
          ),
        )
        ..registrarMovimiento(
          movc(
            '5',
            '40000',
            TipoMovimientoCaja.egreso,
            ClasificacionMovimiento.personal,
          ),
        )
        ..registrarMovimiento(
          movc(
            '6',
            '20000',
            TipoMovimientoCaja.ingreso,
            ClasificacionMovimiento.personal,
          ),
        )
        ..registrarMovimiento(
          movc(
            '7',
            '5000',
            TipoMovimientoCaja.egreso,
            ClasificacionMovimiento.anulacion,
          ),
        );

      final desglose = caja.calcularDesglose();

      expect(desglose.baseApertura, d('100000'));
      expect(desglose.ingresosNegocio, d('276500'));
      expect(desglose.egresosNegocio, d('18000'));
      expect(desglose.cantidadEgresosNegocio, 2);
      expect(desglose.egresosPersonales, d('40000'));
      expect(desglose.ingresosPersonales, d('20000'));
      expect(desglose.devolucionesPorAnulacion, d('5000'));
      expect(desglose.saldoEsperado, caja.calcularSaldoEsperado());
    });

    test('una caja sin movimientos solo tiene la base', () {
      final desglose = Caja(
        't_2026-11-14',
        hoy,
        baseApertura: d('100000'),
      ).calcularDesglose();

      expect(desglose.saldoEsperado, d('100000'));
      expect(desglose.ingresosNegocio, Decimal.zero);
      expect(desglose.cantidadEgresosNegocio, 0);
    });

    test('siempre cuadra: base + entradas − salidas = saldo esperado', () {
      for (final tipo in TipoMovimientoCaja.values) {
        for (final c in ClasificacionMovimiento.values) {
          final caja = Caja('t_2026-11-14', hoy, baseApertura: d('1000'))
            ..registrarMovimiento(movc('a', '300', tipo, c))
            ..registrarMovimiento(movc('b', '70', tipo, c))
            ..registrarMovimiento(
              movc(
                'c',
                '5',
                tipo == TipoMovimientoCaja.ingreso
                    ? TipoMovimientoCaja.egreso
                    : TipoMovimientoCaja.ingreso,
                c,
              ),
            );
          final x = caja.calcularDesglose();

          final suma =
              x.baseApertura +
              x.ingresosNegocio +
              x.ingresosPersonales -
              x.egresosNegocio -
              x.egresosPersonales -
              x.devolucionesPorAnulacion;
          expect(suma, x.saldoEsperado, reason: '$tipo $c');
        }
      }
    });
  });
}
