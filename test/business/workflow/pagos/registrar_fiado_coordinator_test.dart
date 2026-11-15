import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

import '../../componentes/pagos/fakes_pagos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late ClienteRepositorioFalso clientes;
  late FiadoRepositorioFalso fiados;
  late RegistrarFiadoCoordinator coordinador;

  setUp(() {
    clientes = ClienteRepositorioFalso();
    fiados = FiadoRepositorioFalso();
    coordinador = RegistrarFiadoCoordinator(
      ServicioClientes(clientes),
      ServicioFiados(fiados),
    );
  });

  test('buscarClientes busca sin tildes', () async {
    await clientes.guardar(tienda, Cliente('c1', 'María Pérez', ''));
    final encontrados = await coordinador.buscarClientes(tienda, 'perez');
    expect(encontrados.single.getId(), 'c1');
  });

  test('registrarCliente guarda el cliente nuevo', () async {
    final cliente = await coordinador.registrarCliente(tienda, 'Ana', '');
    expect(clientes.de(tienda), [cliente]);
  });

  test('registrarCliente sin nombre propaga el error', () async {
    await expectLater(
      coordinador.registrarCliente(tienda, ' ', ''),
      throwsA(isA<ExcepcionNombreClienteObligatorio>()),
    );
  });

  test('prepararFiado deja el fiado en memoria', () {
    final cliente = Cliente('c1', 'Ana', '');
    final fiado = coordinador.prepararFiado(cliente, d('8400'));
    expect(fiado.getMontoInicial(), d('8400'));
    expect(fiados.datos, isEmpty);
  });

  test('prepararFiado con monto cero propaga el error', () {
    expect(
      () => coordinador.prepararFiado(Cliente('c1', 'Ana', ''), Decimal.zero),
      throwsA(isA<ExcepcionMontoFiadoNoValido>()),
    );
  });
}
