import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:decimal/decimal.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import 'fakes_pagos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra', 'Turbaco');

  late ClienteRepositorioFalso clientes;
  late ServicioClientes servicio;

  setUp(() {
    clientes = ClienteRepositorioFalso();
    servicio = ServicioClientes(clientes);
  });

  group('registrarCliente', () {
    test('cliente nuevo: crea el cliente con id uuid y lo guarda', () async {
      final cliente = await servicio.registrarCliente(
        tienda,
        '  María Pérez ',
        ' 300 412 4521 ',
      );

      expect(cliente.getNombre(), 'María Pérez');
      expect(cliente.getTelefono(), '300 412 4521');
      expect(
        cliente.getId(),
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')),
      );
      expect(clientes.de(tienda), [cliente]);
      expect(cliente.calcularSaldoPendiente().toString(), '0');
    });

    test('sin teléfono queda vacío (DI-26)', () async {
      final cliente = await servicio.registrarCliente(tienda, 'Ana', '');
      expect(cliente.getTelefono(), '');
    });

    for (final nombre in ['', '   ']) {
      test('nombre vacío ("$nombre"): "El nombre del cliente es '
          'obligatorio" y no guarda nada', () async {
        await expectLater(
          servicio.registrarCliente(tienda, nombre, '300'),
          throwsA(
            isA<ExcepcionNombreClienteObligatorio>().having(
              (e) => e.mensaje,
              'mensaje',
              'El nombre del cliente es obligatorio',
            ),
          ),
        );
        expect(clientes.datos.values.expand((l) => l), isEmpty);
      });
    }
  });

  group('buscarClientes', () {
    setUp(() async {
      await clientes.guardar(tienda, Cliente('c1', 'María Pérez', ''));
      await clientes.guardar(tienda, Cliente('c2', 'María José Ruiz', ''));
      await clientes.guardar(tienda, Cliente('c3', 'Pedro Gómez', ''));
      await clientes.guardar(otra, Cliente('c4', 'María Otra', ''));
    });

    test('sin tildes ni mayúsculas y solo de la tienda', () async {
      final encontrados = await servicio.buscarClientes(tienda, 'MARIA');
      expect(encontrados.map((c) => c.getId()), ['c1', 'c2']);
    });

    test('coincidencia parcial', () async {
      final encontrados = await servicio.buscarClientes(tienda, 'gomez');
      expect(encontrados.single.getId(), 'c3');
    });
  });

  group('eliminarCliente (CUS-21)', () {
    Cliente conFiado(String id, EstadoFiado estado, String saldo) {
      final c = Cliente(id, 'María Pérez', '300 412 4521');
      c.agregarFiado(
        Fiado.guardado(
          'f-$id',
          Decimal.parse('25000'),
          DateTime.utc(2026, 11, 1),
          c,
          Decimal.parse(saldo),
          estado,
        ),
      );
      return c;
    }

    test('sin fiados: se elimina', () async {
      final c = Cliente('c1', 'Ana', '');
      await clientes.guardar(tienda, c);
      expect(c.puedeEliminarse(), isTrue);

      await servicio.eliminarCliente(tienda, c);

      expect(clientes.eliminados, ['c1']);
      expect(clientes.de(tienda), isEmpty);
    });

    test('con fiados solo saldados: se elimina', () async {
      final c = conFiado('c2', EstadoFiado.saldado, '0');
      await clientes.guardar(tienda, c);

      await servicio.eliminarCliente(tienda, c);

      expect(clientes.eliminados, ['c2']);
    });

    test('con un fiado pendiente: "No se pueden eliminar los datos: el '
        'cliente aún debe" y no elimina nada', () async {
      final c = conFiado('c3', EstadoFiado.pendiente, '12500');
      await clientes.guardar(tienda, c);
      expect(c.puedeEliminarse(), isFalse);

      await expectLater(
        servicio.eliminarCliente(tienda, c),
        throwsA(
          isA<ExcepcionClienteConSaldo>().having(
            (e) => e.mensaje,
            'mensaje',
            'No se pueden eliminar los datos: el cliente aún debe',
          ),
        ),
      );

      expect(clientes.eliminados, isEmpty);
      expect(clientes.de(tienda), [c]);
    });
  });
}
