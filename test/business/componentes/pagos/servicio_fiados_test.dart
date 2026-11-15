import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import 'fakes_pagos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late FiadoRepositorioFalso fiados;
  late ServicioFiados servicio;
  late Cliente maria;

  setUp(() {
    fiados = FiadoRepositorioFalso();
    servicio = ServicioFiados(fiados);
    maria = Cliente('c1', 'María Pérez', '3004124521');
  });

  group('crearFiado', () {
    test('crea el fiado en memoria: saldo = monto, PENDIENTE, sin '
        'guardarlo', () {
      final fiado = servicio.crearFiado(maria, d('8400'));

      expect(fiado.getCliente(), same(maria));
      expect(fiado.getMontoInicial(), d('8400'));
      expect(fiado.getSaldoPendiente(), d('8400'));
      expect(fiado.getEstado(), EstadoFiado.pendiente);
      expect(fiado.getFechaInicio().isUtc, isTrue);
      expect(fiados.datos, isEmpty);
      expect(maria.obtenerFiadosPendientes(), isEmpty);
    });

    for (final monto in ['0', '-100']) {
      test('monto $monto: "El monto del fiado debe ser mayor que cero"', () {
        expect(
          () => servicio.crearFiado(maria, d(monto)),
          throwsA(
            isA<ExcepcionMontoFiadoNoValido>().having(
              (e) => e.mensaje,
              'mensaje',
              'El monto del fiado debe ser mayor que cero',
            ),
          ),
        );
      });
    }
  });

  test('registrarFiado lo agrega al cliente y lo inserta', () async {
    final fiado = servicio.crearFiado(maria, d('8400'));

    await servicio.registrarFiado(tienda, fiado);

    expect(fiados.de(tienda), [fiado]);
    expect(maria.calcularSaldoPendiente(), d('8400'));
  });

  group('ProcesadorFiado', () {
    late ProcesadorFiado procesador;
    setUp(() => procesador = ProcesadorFiado(servicio));

    test('admite solo el fiado', () {
      expect(procesador.admite(servicio.crearFiado(maria, d('1'))), isTrue);
      expect(procesador.admite(PagoNequi('n1', d('1'), null)), isFalse);
    });

    test('procesar registra el fiado', () async {
      final fiado = servicio.crearFiado(maria, d('5000'));
      final venta = Venta('v1', [fiado], d('5000'), DateTime.utc(2026));

      await procesador.procesar(tienda, venta, fiado);

      expect(fiados.de(tienda), [fiado]);
    });
  });
}
