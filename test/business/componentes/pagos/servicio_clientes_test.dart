import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
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
}
