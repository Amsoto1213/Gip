import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_caja_cerrada.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

import '../gestion_caja/fakes_caja.dart';

/// ResolutorCajaCerrada (CUS-22, DA-66, DI-45): el movimiento se acepta en su
/// caja y se recalcula la diferencia del cierre.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  final dia = DateTime(2026, 11, 14);
  final idCaja = 't1_2026-11-14';

  late CajaRepositorioFalso cajas;
  late ResolutorCajaCerrada resolutor;

  setUp(() {
    cajas = CajaRepositorioFalso();
    resolutor = ResolutorCajaCerrada(cajas);
  });

  MovimientoCaja ingreso(String id, String valor) => MovimientoCaja(
    id,
    d(valor),
    'Venta',
    ClasificacionMovimiento.negocio,
    TipoMovimientoCaja.ingreso,
    dia,
  );

  /// Una caja que se cerró con [contado] teniendo 30.000 de saldo esperado.
  Future<void> cajaCerrada({String contado = '30000'}) async {
    final caja = Caja(idCaja, dia);
    await cajas.crear(tienda, caja);
    final venta = caja.registrarMovimiento(ingreso('m1', '30000'));
    await cajas.registrarMovimiento(tienda, caja, venta);
    caja.cerrar(d(contado));
    await cajas.cerrar(tienda, caja);
  }

  /// Un movimiento que llegó de otro equipo después del cierre.
  Future<void> llegoTarde(String id, String valor) async {
    final caja = (await cajas.buscarPorId(tienda, idCaja))!;
    await cajas.registrarMovimiento(tienda, caja, ingreso(id, valor));
  }

  ConflictoSincronizacion conflicto([List<String>? ids]) =>
      ConflictoSincronizacion(
        'MOVIMIENTO_CAJA_CERRADA:m2',
        TipoConflicto.movimientoCajaCerrada,
        'Llegó un movimiento a una caja ya cerrada',
        ids ?? [idCaja, 'm2'],
        DateTime.utc(2026, 11, 15),
      );

  test('admite solo movimiento en caja cerrada', () {
    for (final tipo in TipoConflicto.values) {
      expect(
        resolutor.admite(
          ConflictoSincronizacion('x', tipo, 'd', [idCaja], DateTime.utc(2026)),
        ),
        tipo == TipoConflicto.movimientoCajaCerrada,
        reason: '$tipo',
      );
    }
  });

  test('recalcula la diferencia con el movimiento que llegó tarde', () async {
    await cajaCerrada();
    await llegoTarde('m2', '2000');

    await resolutor.resolver(tienda, conflicto(), const []);

    final (_, diferencia, _) = cajas.cierres[tienda.getId()]![idCaja]!;
    // Esperado 32.000, contado 30.000: faltan 2.000.
    expect(diferencia, d('-2000'));
  });

  test('guarda con cajas.cerrar sin cambiar el efectivo contado ni la fecha '
      'del cierre', () async {
    await cajaCerrada(contado: '29000');
    final antes = cajas.cierres[tienda.getId()]![idCaja]!;
    await llegoTarde('m2', '500');

    await resolutor.resolver(tienda, conflicto(), const []);

    final (contado, _, cierre) = cajas.cierres[tienda.getId()]![idCaja]!;
    expect(contado, d('29000'));
    expect(cierre, antes.$3);
  });

  test('la decisión no se usa: el dinero registrado no se pierde', () async {
    await cajaCerrada();
    await llegoTarde('m2', '2000');

    await resolutor.resolver(tienda, conflicto(), ['m2']);

    final (_, diferencia, _) = cajas.cierres[tienda.getId()]![idCaja]!;
    expect(diferencia, d('-2000'));
    expect(
      (await cajas.buscarPorId(tienda, idCaja))!.getMovimientos(),
      hasLength(2),
    );
  });

  test('usa el primer id del conflicto como la caja', () async {
    await cajaCerrada();
    await llegoTarde('m2', '2000');

    // Los demás ids (el movimiento) no se miran.
    await resolutor.resolver(
      tienda,
      conflicto([idCaja, 'cualquiera']),
      const [],
    );

    expect(cajas.cierres[tienda.getId()]![idCaja]!.$2, d('-2000'));
  });

  test('si la caja no aparece: error', () async {
    await expectLater(
      resolutor.resolver(tienda, conflicto(), const []),
      throwsA(isA<ExcepcionRegistrosDelConflictoNoEncontrados>()),
    );
  });

  test('la caja de otra tienda no se encuentra', () async {
    await cajaCerrada();
    final otra = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');

    await expectLater(
      resolutor.resolver(otra, conflicto(), const []),
      throwsA(isA<ExcepcionRegistrosDelConflictoNoEncontrados>()),
    );
  });

  test(
    'si la caja no está cerrada, no hay diferencia que recalcular',
    () async {
      await cajas.crear(tienda, Caja(idCaja, dia));

      await expectLater(
        resolutor.resolver(tienda, conflicto(), const []),
        throwsA(isA<ExcepcionCajaNoCerrada>()),
      );
    },
  );

  test('si guardar el cierre falla, el error llega', () async {
    await cajaCerrada();
    await llegoTarde('m2', '2000');
    cajas.fallar = true;

    await expectLater(
      resolutor.resolver(tienda, conflicto(), const []),
      throwsA(isA<StateError>()),
    );
  });
}
