import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/presentation/vender/fiar_view_model.dart';
import 'package:mocktail/mocktail.dart';

import 'venta_de_prueba.dart';

class RegistrarFiadoFalso extends Mock implements RegistrarFiadoCoordinator {}

/// Para `any()` con [Tienda].
class _TiendaFalsa extends Fake implements Tienda {}

void main() {
  late VentaDePrueba prueba;
  late Cliente maria;

  setUpAll(() => registerFallbackValue(_TiendaFalsa()));

  setUp(() async {
    prueba = await VentaDePrueba.crear();
    maria = Cliente('c1', 'María Pérez', '300 412 4521');
    maria.agregarFiado(
      Fiado.guardado(
        'f0',
        d('47500'),
        DateTime.utc(2026, 11),
        maria,
        d('47500'),
        EstadoFiado.pendiente,
      ),
    );
    await prueba.clientes.guardar(tiendaPrueba, maria);
    await prueba.clientes.guardar(
      tiendaPrueba,
      Cliente('c2', 'María José Ruiz', ''),
    );
  });

  FiarViewModel crear({String falta = '8400'}) =>
      FiarViewModel(prueba.registrarFiado, tiendaPrueba, (
        total: d('13400'),
        yaPago: d('13400') - d(falta),
        detallePagado: 'efectivo',
        falta: d(falta),
      ));

  test('sugiere fiar lo que falta', () {
    expect(crear().montoInicial, '8.400');
    expect(crear(falta: '0').montoInicial, '');
  });

  test('busca sin tildes ni mayúsculas y sin texto no muestra nada', () async {
    final vm = crear();
    await vm.buscar('MARIA');
    expect(vm.clientes.map((c) => c.getId()), ['c1', 'c2']);

    await vm.buscar('  ');
    expect(vm.clientes, isEmpty);
    expect(vm.sinResultados, isFalse);

    await vm.buscar('zz');
    expect(vm.sinResultados, isTrue);
  });

  test('una respuesta vieja no pisa la búsqueda nueva', () async {
    final falso = RegistrarFiadoFalso();
    final lenta = Completer<List<Cliente>>();
    when(() => falso.buscarClientes(tiendaPrueba, 'mar'))
        .thenAnswer((_) => lenta.future);
    when(() => falso.buscarClientes(tiendaPrueba, 'maria'))
        .thenAnswer((_) async => [maria]);
    final vm = FiarViewModel(falso, tiendaPrueba, (
      total: d('1'),
      yaPago: d('0'),
      detallePagado: 'nada aún',
      falta: d('1'),
    ));

    final primera = vm.buscar('mar');
    await vm.buscar('maria');
    lenta.complete([Cliente('x', 'Otro', '')]);
    await primera;

    expect(vm.clientes, [maria]);
  });

  test('si falla la búsqueda muestra el mensaje', () async {
    final falso = RegistrarFiadoFalso();
    when(() => falso.buscarClientes(any(), any()))
        .thenThrow(StateError('disco'));
    final vm = FiarViewModel(falso, tiendaPrueba, (
      total: d('1'),
      yaPago: d('0'),
      detallePagado: 'nada aún',
      falta: d('1'),
    ));
    await vm.buscar('ana');
    expect(vm.errorBusqueda, FiarViewModel.mensajeErrorBuscar);
  });

  test('elegir: el cliente queda aunque cambie la búsqueda y da la deuda '
      'total', () async {
    final vm = crear();
    await vm.buscar('perez');
    expect(vm.puedeAgregar, isFalse);
    vm.elegir(maria);
    await vm.buscar('ruiz');

    expect(vm.cliente, maria);
    expect(vm.clientes.map((c) => c.getId()), ['c1', 'c2']);
    expect(vm.deudaTotal, d('55900')); // 47.500 + 8.400
    expect(vm.puedeAgregar, isTrue);
  });

  test('agregar prepara el fiado en memoria, sin guardarlo', () {
    final vm = crear();
    vm.elegir(maria);
    vm.cambiarMonto('8.400');

    final fiado = vm.agregar()!;

    expect(fiado.getCliente(), maria);
    expect(fiado.getMontoInicial(), d('8400'));
    expect(prueba.fiados.datos, isEmpty);
  });

  for (final monto in ['0', '', '-500', 'abc']) {
    test('monto "$monto": "El monto del fiado debe ser mayor que cero"', () {
      final vm = crear();
      vm.elegir(maria);
      vm.cambiarMonto(monto);

      expect(vm.agregar(), isNull);
      expect(vm.errorMonto, 'El monto del fiado debe ser mayor que cero');
      expect(vm.deudaTotal, isNull);

      vm.cambiarMonto('1.000');
      expect(vm.errorMonto, isNull);
    });
  }

  group('cliente nuevo', () {
    test('lo registra, lo deja elegido y sale del formulario', () async {
      final vm = crear();
      vm.mostrarClienteNuevo(true);
      expect(vm.creandoCliente, isTrue);

      final ok = await vm.registrarCliente('Ana Gómez', '');

      expect(ok, isTrue);
      expect(vm.creandoCliente, isFalse);
      expect(vm.cliente!.getNombre(), 'Ana Gómez');
      expect(vm.clientes, [vm.cliente]);
      expect(prueba.clientes.de(tiendaPrueba), contains(vm.cliente));
      expect(vm.deudaTotal, d('8400'));
    });

    test('nombre vacío: "El nombre del cliente es obligatorio"', () async {
      final vm = crear();
      vm.mostrarClienteNuevo(true);

      final ok = await vm.registrarCliente('  ', '300');

      expect(ok, isFalse);
      expect(vm.errorNombre, 'El nombre del cliente es obligatorio');
      expect(vm.creandoCliente, isTrue);
      expect(vm.cliente, isNull);
    });

    test('si falla al guardar muestra el mensaje', () async {
      final falso = RegistrarFiadoFalso();
      when(() => falso.registrarCliente(any(), any(), any()))
          .thenThrow(StateError('disco'));
      final vm = FiarViewModel(falso, tiendaPrueba, (
        total: d('1'),
        yaPago: d('0'),
        detallePagado: 'nada aún',
        falta: d('1'),
      ));
      expect(await vm.registrarCliente('Ana', ''), isFalse);
      expect(vm.errorNombre, FiarViewModel.mensajeErrorRegistrar);
    });
  });
}
