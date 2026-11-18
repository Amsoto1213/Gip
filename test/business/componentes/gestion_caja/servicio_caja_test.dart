import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

import 'fakes_caja.dart';

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  Decimal d(String v) => Decimal.parse(v);

  late CajaRepositorioFalso cajas;
  late ServicioCaja servicio;

  setUp(() {
    cajas = CajaRepositorioFalso();
    servicio = ServicioCaja(cajas);
  });

  test('idCaja se forma con la tienda y la fecha (DA-62)', () {
    expect(
      ServicioCaja.idCaja(tienda, DateTime(2026, 3, 7)),
      '11111111-1111-4111-8111-111111111111_2026-03-07',
    );
  });

  group('registrarIngreso', () {
    test('abre la caja de hoy y registra un INGRESO del NEGOCIO', () async {
      final mov = await servicio.registrarIngreso(
        tienda,
        d('32000'),
        'Venta v1',
      );

      expect(mov.getValor(), d('32000'));
      expect(mov.getTipo(), TipoMovimientoCaja.ingreso);
      expect(mov.getClasificacion(), ClasificacionMovimiento.negocio);
      expect(mov.getDescripcion(), 'Venta v1');
      expect(mov.getFecha().isUtc, isTrue);

      final hoy = ServicioCaja.diaLocal(DateTime.now());
      final caja = await cajas.buscarPorFecha(tienda, hoy);
      expect(caja!.getId(), ServicioCaja.idCaja(tienda, hoy));
      expect(caja.calcularSaldoEsperado(), d('32000'));
    });

    test('la segunda venta del día usa la misma caja', () async {
      await servicio.registrarIngreso(tienda, d('1000'), 'a');
      await servicio.registrarIngreso(tienda, d('2500'), 'b');

      expect(cajas.cajas[tienda.getId()], hasLength(1));
      final caja = await cajas.buscarPorFecha(
        tienda,
        ServicioCaja.diaLocal(DateTime.now()),
      );
      expect(caja!.calcularSaldoEsperado(), d('3500'));
    });

    test('rechaza un valor cero o negativo y no guarda nada', () async {
      for (final v in ['0', '-1']) {
        await expectLater(
          servicio.registrarIngreso(tienda, d(v), 'x'),
          throwsA(isA<ExcepcionValorMovimientoNoValido>()),
        );
      }
      expect(cajas.cajas, isEmpty);
      expect(cajas.movimientos, isEmpty);
    });
  });

  group('registrarMovimientoManual (CUS-11)', () {
    test('un egreso PERSONAL abre la caja y resta del saldo', () async {
      final mov = await servicio.registrarMovimientoManual(
        tienda,
        TipoMovimientoCaja.egreso,
        ClasificacionMovimiento.personal,
        d('40000'),
        'Retiro',
      );

      expect(mov.getValor(), d('40000'));
      expect(mov.getTipo(), TipoMovimientoCaja.egreso);
      expect(mov.getClasificacion(), ClasificacionMovimiento.personal);
      expect(mov.getDescripcion(), 'Retiro');
      expect(mov.getFecha().isUtc, isTrue);
      final caja = await cajas.buscarPorFecha(
        tienda,
        ServicioCaja.diaLocal(DateTime.now()),
      );
      expect(caja!.calcularSaldoEsperado(), d('-40000'));
    });

    test('un egreso del NEGOCIO y un ingreso del NEGOCIO se guardan en la '
        'misma caja', () async {
      await servicio.registrarMovimientoManual(
        tienda,
        TipoMovimientoCaja.egreso,
        ClasificacionMovimiento.negocio,
        d('12000'),
        'Hielo',
      );
      await servicio.registrarMovimientoManual(
        tienda,
        TipoMovimientoCaja.ingreso,
        ClasificacionMovimiento.negocio,
        d('100000'),
        'Base de apertura',
      );

      expect(cajas.cajas[tienda.getId()], hasLength(1));
      final caja = await cajas.buscarPorFecha(
        tienda,
        ServicioCaja.diaLocal(DateTime.now()),
      );
      expect(caja!.getMovimientos(), hasLength(2));
      expect(caja.calcularSaldoEsperado(), d('88000'));
    });

    test('rechaza la clasificación ANULACION sin guardar nada', () async {
      for (final tipo in TipoMovimientoCaja.values) {
        await expectLater(
          servicio.registrarMovimientoManual(
            tienda,
            tipo,
            ClasificacionMovimiento.anulacion,
            d('5000'),
            'Devolución',
          ),
          throwsA(
            isA<ExcepcionClasificacionNoPermitida>().having(
              (e) => e.mensaje,
              'mensaje',
              'Esa clasificación solo la usa la anulación de ventas',
            ),
          ),
        );
      }
      expect(cajas.cajas, isEmpty);
      expect(cajas.movimientos, isEmpty);
    });

    test('la clasificación se valida antes que el valor (pasos 5 y 9)', () {
      expect(
        servicio.registrarMovimientoManual(
          tienda,
          TipoMovimientoCaja.egreso,
          ClasificacionMovimiento.anulacion,
          d('0'),
          'x',
        ),
        throwsA(isA<ExcepcionClasificacionNoPermitida>()),
      );
    });

    test('rechaza un valor cero o negativo y no guarda nada', () async {
      for (final v in ['0', '-1']) {
        await expectLater(
          servicio.registrarMovimientoManual(
            tienda,
            TipoMovimientoCaja.egreso,
            ClasificacionMovimiento.negocio,
            d(v),
            'x',
          ),
          throwsA(
            isA<ExcepcionValorMovimientoNoValido>().having(
              (e) => e.mensaje,
              'mensaje',
              'El valor debe ser mayor que cero',
            ),
          ),
        );
      }
      expect(cajas.cajas, isEmpty);
      expect(cajas.movimientos, isEmpty);
    });
  });
}
