import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import '../gestion_caja/fakes_caja.dart';
import '../gestion_inventario/fakes_catalogo.dart';
import 'fakes_pagos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late FiadoRepositorioFalso fiados;
  late CajaRepositorioFalso cajas;
  late UnidadTrabajoFalsa unidad;
  late ServicioAbonos servicio;
  late Fiado fiado;

  setUp(() {
    fiados = FiadoRepositorioFalso();
    cajas = CajaRepositorioFalso();
    unidad = UnidadTrabajoFalsa([fiados, cajas]);
    fiados.unidad = unidad;
    cajas.unidad = unidad;
    servicio = ServicioAbonos(fiados, ServicioCaja(cajas), unidad);
    final maria = Cliente('c1', 'María Pérez', '');
    fiado = Fiado('f1', d('25000'), DateTime.utc(2026, 11, 1), maria);
    maria.agregarFiado(fiado);
  });

  const mensaje =
      'El abono debe ser mayor que cero y no puede superar el saldo pendiente';

  test('abono parcial en efectivo: baja el saldo y entra a la caja', () async {
    final abono = await servicio.registrarAbono(
      tienda,
      fiado,
      d('10000'),
      MedioPago.efectivo,
      'ignorada',
    );

    expect(fiado.getSaldoPendiente(), d('15000'));
    expect(fiado.getEstado(), EstadoFiado.pendiente);
    expect(abono.getReferencia(), isNull);
    expect(abono.getFecha().isUtc, isTrue);
    expect(fiados.abonos, [abono]);
    final movimiento = cajas.movimientosDe(tienda).single;
    expect(movimiento.getValor(), d('10000'));
    expect(movimiento.getDescripcion(), 'Abono');
    expect(movimiento.getClasificacion(), ClasificacionMovimiento.negocio);
    expect(movimiento.getTipo(), TipoMovimientoCaja.ingreso);
    expect(unidad.transacciones, 1);
    expect(fiados.guardadosEnTransaccion, [true]);
  });

  test('abono que salda el fiado lo pasa a SALDADO', () async {
    await servicio.registrarAbono(
      tienda,
      fiado,
      d('25000'),
      MedioPago.efectivo,
      null,
    );
    expect(fiado.getSaldoPendiente(), Decimal.zero);
    expect(fiado.getEstado(), EstadoFiado.saldado);
  });

  test('por Nequi no toca la caja y guarda la referencia', () async {
    final abono = await servicio.registrarAbono(
      tienda,
      fiado,
      d('5000'),
      MedioPago.nequi,
      ' 123456 ',
    );
    expect(abono.getReferencia(), '123456');
    expect(abono.getMedio(), MedioPago.nequi);
    expect(cajas.movimientosDe(tienda), isEmpty);
    expect(cajas.cajas, isEmpty);
    expect(fiados.abonos, [abono]);
  });

  test('por Nequi sin referencia o vacía queda nula', () async {
    final a = await servicio.registrarAbono(
      tienda,
      fiado,
      d('1000'),
      MedioPago.nequi,
      '  ',
    );
    final b = await servicio.registrarAbono(
      tienda,
      fiado,
      d('1000'),
      MedioPago.nequi,
      null,
    );
    expect(a.getReferencia(), isNull);
    expect(b.getReferencia(), isNull);
  });

  for (final monto in ['0', '-100', '25000.01']) {
    test('monto $monto: "Monto no válido" y no guarda nada', () async {
      await expectLater(
        servicio.registrarAbono(
          tienda,
          fiado,
          d(monto),
          MedioPago.efectivo,
          null,
        ),
        throwsA(
          isA<ExcepcionMontoAbonoNoValido>().having(
            (e) => e.mensaje,
            'mensaje',
            mensaje,
          ),
        ),
      );
      expect(fiado.getSaldoPendiente(), d('25000'));
      expect(fiados.abonos, isEmpty);
      expect(cajas.movimientosDe(tienda), isEmpty);
      expect(unidad.transacciones, 0);
    });
  }

  test('el saldo exacto es válido (no hay cambio)', () async {
    await servicio.registrarAbono(
      tienda,
      fiado,
      d('25000'),
      MedioPago.nequi,
      null,
    );
    expect(fiado.getEstado(), EstadoFiado.saldado);
  });

  test('rollback: si falla la caja no queda el abono guardado', () async {
    cajas.fallar = true;
    await expectLater(
      servicio.registrarAbono(
        tienda,
        fiado,
        d('10000'),
        MedioPago.efectivo,
        null,
      ),
      throwsA(isA<StateError>()),
    );
    expect(fiados.abonos, isEmpty);
    expect(cajas.movimientosDe(tienda), isEmpty);
  });

  test('rollback: si falla el guardado del abono no entra a la caja', () async {
    fiados.fallar = true;
    await expectLater(
      servicio.registrarAbono(
        tienda,
        fiado,
        d('10000'),
        MedioPago.efectivo,
        null,
      ),
      throwsA(isA<StateError>()),
    );
    expect(fiados.abonos, isEmpty);
    expect(cajas.movimientosDe(tienda), isEmpty);
  });
}
