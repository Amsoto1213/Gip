import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/gestion_inventario/fakes_catalogo.dart';
import '../../componentes/pagos/fakes_pagos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  group('RegistrarAbonoCoordinator', () {
    late FiadoRepositorioFalso fiados;
    late RegistrarAbonoCoordinator coordinador;
    late Fiado fiado;

    setUp(() {
      fiados = FiadoRepositorioFalso();
      final cajas = CajaRepositorioFalso();
      coordinador = RegistrarAbonoCoordinator(
        ServicioAbonos(
          fiados,
          ServicioCaja(cajas),
          UnidadTrabajoFalsa([fiados, cajas]),
        ),
      );
      fiado = Fiado(
        'f1',
        d('9000'),
        DateTime.utc(2026, 11, 1),
        Cliente('c1', 'Ana', ''),
      );
    });

    test('registrarAbono delega en el servicio y devuelve el abono', () async {
      final abono = await coordinador.registrarAbono(
        tienda,
        fiado,
        d('4000'),
        MedioPago.efectivo,
        null,
      );
      expect(fiados.abonos, [abono]);
      expect(fiado.getSaldoPendiente(), d('5000'));
    });

    test('registrarAbono propaga el monto no válido', () async {
      await expectLater(
        coordinador.registrarAbono(
          tienda,
          fiado,
          d('9001'),
          MedioPago.nequi,
          null,
        ),
        throwsA(isA<ExcepcionMontoAbonoNoValido>()),
      );
    });
  });

  group('ConsultarClienteCoordinator', () {
    late ClienteRepositorioFalso clientes;
    late ConsultarClienteCoordinator coordinador;

    setUp(() {
      clientes = ClienteRepositorioFalso();
      coordinador = ConsultarClienteCoordinator(
        ServicioClientes(clientes),
        ServicioFiados(FiadoRepositorioFalso()),
      );
    });

    test('buscarClientes busca sin mayúsculas ni tildes', () async {
      await clientes.guardar(tienda, Cliente('c1', 'María Pérez', ''));
      await clientes.guardar(tienda, Cliente('c2', 'José Barrios', ''));
      final r = await coordinador.buscarClientes(tienda, 'PEREZ');
      expect(r.map((c) => c.getId()), ['c1']);
    });

    test('consultarSaldoTotal suma solo los fiados pendientes', () {
      final maria = Cliente('c1', 'María', '');
      final f1 = Fiado('f1', d('20000'), DateTime.utc(2026, 11, 1), maria);
      final f2 = Fiado('f2', d('5000'), DateTime.utc(2026, 11, 2), maria);
      maria
        ..agregarFiado(f1)
        ..agregarFiado(f2);
      f2.registrarAbono(
        Abono(
          'a1',
          d('5000'),
          DateTime.utc(2026, 11, 3),
          MedioPago.nequi,
          null,
        ),
      );
      expect(coordinador.consultarSaldoTotal(maria), d('20000'));
    });
  });
}
