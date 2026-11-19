import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_abono_excedido.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

import '../gestion_caja/fakes_caja.dart';
import '../pagos/fakes_pagos.dart';

/// ResolutorAbonoExcedido (CUS-22, DA-66, DI-45): anula los abonos que sobran
/// y devuelve el efectivo por la caja.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15, 15);
  final cliente = Cliente('c1', 'María Pérez', '');

  late FiadoRepositorioFalso fiados;
  late CajaRepositorioFalso cajas;
  late ServicioCaja servicioCaja;
  late ResolutorAbonoExcedido resolutor;

  setUp(() {
    fiados = FiadoRepositorioFalso();
    cajas = CajaRepositorioFalso();
    servicioCaja = ServicioCaja(cajas);
    resolutor = ResolutorAbonoExcedido(fiados, servicioCaja);
  });

  Abono abono(
    String id,
    String monto, {
    MedioPago medio = MedioPago.efectivo,
    bool anulado = false,
  }) => Abono(id, d(monto), fecha, medio, null, anulado: anulado);

  /// Un fiado de 10.000 con los abonos dados; el saldo se recalcula.
  Future<Fiado> fiadoCon(List<Abono> abonos, {String monto = '10000'}) async {
    final f = Fiado.guardado(
      'f1',
      d(monto),
      fecha,
      cliente,
      d(monto),
      EstadoFiado.pendiente,
      abonos,
    )..recalcularSaldo();
    await fiados.crear(tienda, f);
    fiados.guardadosEnTransaccion.clear();
    return f;
  }

  ConflictoSincronizacion conflicto(List<Abono> abonos) =>
      ConflictoSincronizacion(
        'ABONO_EXCEDE_SALDO:f1',
        TipoConflicto.abonoExcedeSaldo,
        'Los abonos suman más de lo que se debía',
        ['f1', ...abonos.map((a) => a.getId())],
        fecha,
      );

  group('admite', () {
    test('solo abono excede saldo', () {
      for (final tipo in TipoConflicto.values) {
        expect(
          resolutor.admite(
            ConflictoSincronizacion('x', tipo, 'd', ['f1'], fecha),
          ),
          tipo == TipoConflicto.abonoExcedeSaldo,
          reason: '$tipo',
        );
      }
    });
  });

  group('anular los abonos elegidos', () {
    test('anula el abono, devuelve el efectivo por la caja y recalcula el '
        'saldo', () async {
      // Dos equipos sin internet recibieron cada uno 8.000: sobran 6.000.
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      final f = await fiadoCon([a1, a2]);
      expect(f.getSaldoPendiente(), d('-6000'));

      await resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']);

      expect(a2.isAnulado(), isTrue);
      expect(a1.isAnulado(), isFalse);
      expect(fiados.abonosAnulados, [a2]);
      expect(f.getSaldoPendiente(), d('2000'));
      expect(f.getEstado(), EstadoFiado.pendiente);
      expect(fiados.actualizados, [f]);
    });

    test(
      'la devolución sale de la caja: egreso de ANULACION por el monto',
      () async {
        final a1 = abono('a1', '8000');
        final a2 = abono('a2', '8000');
        await fiadoCon([a1, a2]);

        await resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']);

        final movimiento = cajas.movimientosDe(tienda).single;
        expect(movimiento.getTipo(), TipoMovimientoCaja.egreso);
        expect(
          movimiento.getClasificacion(),
          ClasificacionMovimiento.anulacion,
        );
        expect(movimiento.getValor(), d('8000'));
        expect(movimiento.getDescripcion(), 'Devolución abono');
      },
    );

    test('un abono por Nequi se anula pero no mueve la caja (la devolución se '
        'hace fuera del sistema)', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000', medio: MedioPago.nequi);
      await fiadoCon([a1, a2]);

      await resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']);

      expect(a2.isAnulado(), isTrue);
      expect(fiados.abonosAnulados, [a2]);
      expect(cajas.movimientosDe(tienda), isEmpty);
    });

    test(
      'con varios abonos devuelve uno por cada efectivo, no el Nequi',
      () async {
        final a1 = abono('a1', '6000');
        final a2 = abono('a2', '3000');
        final a3 = abono('a3', '2000', medio: MedioPago.nequi);
        final a4 = abono('a4', '4000');
        final f = await fiadoCon([a1, a2, a3, a4]);
        // 6000 + 3000 + 2000 + 4000 = 15000 sobre 10000: sobran 5000.

        await resolutor.resolver(tienda, conflicto([a1, a2, a3, a4]), [
          'a2',
          'a3',
          'a4',
        ]);

        expect(fiados.abonosAnulados.map((a) => a.getId()), ['a2', 'a3', 'a4']);
        expect(cajas.movimientosDe(tienda).map((m) => m.getValor()), [
          d('3000'),
          d('4000'),
        ]);
        expect(f.getSaldoPendiente(), d('4000'));
      },
    );

    test('si el saldo queda en cero, el fiado queda SALDADO', () async {
      final a1 = abono('a1', '10000');
      final a2 = abono('a2', '3000');
      final f = await fiadoCon([a1, a2]);

      await resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']);

      expect(f.getSaldoPendiente(), Decimal.zero);
      expect(f.getEstado(), EstadoFiado.saldado);
    });
  });

  group('lo que no se debe repetir ni inventar', () {
    test('un abono que ya estaba anulado no se devuelve otra vez', () async {
      final a1 = abono('a1', '10000');
      final a2 = abono('a2', '3000', anulado: true);
      final a3 = abono('a3', '2000');
      await fiadoCon([a1, a2, a3]);

      await resolutor.resolver(tienda, conflicto([a1, a2, a3]), ['a2', 'a3']);

      // Solo a3: a2 ya estaba anulado y su dinero ya se devolvió.
      expect(fiados.abonosAnulados, [a3]);
      expect(cajas.movimientosDe(tienda).map((m) => m.getValor()), [d('2000')]);
    });

    test('un id elegido que no es de ese fiado se ignora', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      await fiadoCon([a1, a2]);

      await resolutor.resolver(tienda, conflicto([a1, a2]), ['a2', 'otro']);

      expect(fiados.abonosAnulados, [a2]);
    });
  });

  group('la decisión tiene que dejar el saldo sin sobrante', () {
    test('si con los abonos elegidos el saldo sigue negativo: error y no se '
        'escribe nada', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      final a3 = abono('a3', '8000');
      final f = await fiadoCon([a1, a2, a3]);
      // Debe 10.000 y hay 24.000: anular uno deja 16.000 → aún sobra.

      await expectLater(
        resolutor.resolver(tienda, conflicto([a1, a2, a3]), ['a3']),
        throwsA(
          isA<ExcepcionAbonoSigueExcedido>().having(
            (e) => e.mensaje,
            'mensaje',
            'Con esos abonos el fiado todavía queda con saldo negativo. Marque '
                'más abonos',
          ),
        ),
      );

      expect(a3.isAnulado(), isFalse);
      expect(fiados.abonosAnulados, isEmpty);
      expect(fiados.actualizados, isEmpty);
      expect(cajas.movimientosDe(tienda), isEmpty);
      expect(f.getSaldoPendiente(), d('-14000'));
    });

    test('sin elegir nada y con el saldo negativo: error', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      await fiadoCon([a1, a2]);

      await expectLater(
        resolutor.resolver(tienda, conflicto([a1, a2]), const []),
        throwsA(isA<ExcepcionAbonoSigueExcedido>()),
      );
    });

    test('sin elegir nada y con el saldo ya bien (se corrigió en otro '
        'equipo): no hace nada y no falla', () async {
      final a1 = abono('a1', '4000');
      final a2 = abono('a2', '3000');
      final f = await fiadoCon([a1, a2]);

      await resolutor.resolver(tienda, conflicto([a1, a2]), const []);

      expect(fiados.abonosAnulados, isEmpty);
      expect(cajas.movimientosDe(tienda), isEmpty);
      expect(f.getSaldoPendiente(), d('3000'));
      // Igual deja guardado el saldo recalculado.
      expect(fiados.actualizados, [f]);
    });
  });

  group('errores', () {
    test('si el fiado no aparece: error y no cambia nada', () async {
      final a1 = abono('a1', '8000');

      await expectLater(
        resolutor.resolver(tienda, conflicto([a1]), ['a1']),
        throwsA(isA<ExcepcionRegistrosDelConflictoNoEncontrados>()),
      );
      expect(cajas.movimientosDe(tienda), isEmpty);
    });

    test('si la caja de hoy ya está cerrada, la devolución falla y el error '
        'llega', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      await fiadoCon([a1, a2]);
      await servicioCaja.cerrarCaja(tienda, Decimal.zero);

      await expectLater(
        resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']),
        throwsA(isA<ExcepcionCajaCerrada>()),
      );
    });

    test('si guardar el abono anulado falla, el error llega', () async {
      final a1 = abono('a1', '8000');
      final a2 = abono('a2', '8000');
      await fiadoCon([a1, a2]);
      fiados.fallar = true;

      await expectLater(
        resolutor.resolver(tienda, conflicto([a1, a2]), ['a2']),
        throwsA(isA<StateError>()),
      );
    });
  });
}
