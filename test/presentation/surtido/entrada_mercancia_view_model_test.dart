import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

class CoordinadorFalso extends Mock
    implements RegistrarEntradaMercanciaCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final aceite = Producto(
    'p1',
    'ACE-1',
    'Aceite 1 L',
    UnidadMedida.unidad,
    null,
    Decimal.parse('11000'),
  );
  Decimal d(String v) => Decimal.parse(v);

  late CoordinadorFalso coordinador;
  late EntradaMercanciaViewModel vm;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(aceite);
    registerFallbackValue(Decimal.zero);
  });

  setUp(() {
    coordinador = CoordinadorFalso();
    vm = EntradaMercanciaViewModel(coordinador, tienda);
    when(() => coordinador.verificarCosto(any(), any(), any()))
        .thenAnswer((_) async => false);
  });
  tearDown(() => vm.dispose());

  EntradaMercancia entradaCon(String stock) => EntradaMercancia(
    'e1',
    ItemInventario('i1', aceite, d(stock)),
    d('24'),
    DateTime.utc(2026, 11, 14),
    d('9400'),
    null,
  );

  group('leerCantidad', () {
    test('acepta enteros y decimales con coma o punto', () {
      expect(EntradaMercanciaViewModel.leerCantidad('24'), d('24'));
      expect(EntradaMercanciaViewModel.leerCantidad('2,5'), d('2.5'));
      expect(EntradaMercanciaViewModel.leerCantidad(' 2.5 '), d('2.5'));
      expect(EntradaMercanciaViewModel.leerCantidad('-1'), d('-1'));
    });

    test('devuelve null si no es un número', () {
      expect(EntradaMercanciaViewModel.leerCantidad(''), isNull);
      expect(EntradaMercanciaViewModel.leerCantidad('dos'), isNull);
    });
  });

  test('total de la compra = cantidad x costo, null si falta uno', () async {
    expect(vm.totalCompra, isNull);
    vm.cambiarCantidad('24');
    expect(vm.totalCompra, isNull);
    await vm.cambiarCosto('9.400');
    expect(vm.costo, d('9400'));
    expect(vm.totalCompra, d('225600'));
  });

  test('los botones − y + suman de a uno y no bajan de cero', () {
    expect(vm.sumarCantidad(Decimal.one), Decimal.one);
    expect(vm.sumarCantidad(Decimal.one), d('2'));
    vm
      ..sumarCantidad(-Decimal.one)
      ..sumarCantidad(-Decimal.one)
      ..sumarCantidad(-Decimal.one);
    expect(vm.cantidad, Decimal.zero);
  });

  group('verificarCosto', () {
    test('sin producto no pregunta al coordinador', () async {
      await vm.cambiarCosto('9400');
      verifyNever(() => coordinador.verificarCosto(any(), any(), any()));
      expect(vm.costoDifiere, isFalse);
    });

    test('muestra la advertencia si el costo difiere', () async {
      when(() => coordinador.verificarCosto(tienda, aceite, d('9400')))
          .thenAnswer((_) async => true);
      await vm.elegirProducto(aceite);

      await vm.cambiarCosto('9.400');

      expect(vm.costoDifiere, isTrue);
      verify(() => coordinador.verificarCosto(tienda, aceite, d('9400')))
          .called(1);
    });

    test('al corregir el costo la advertencia se va', () async {
      when(() => coordinador.verificarCosto(tienda, aceite, d('9400')))
          .thenAnswer((_) async => true);
      await vm.elegirProducto(aceite);
      await vm.cambiarCosto('9400');
      expect(vm.costoDifiere, isTrue);

      await vm.cambiarCosto('8600');
      expect(vm.costoDifiere, isFalse);
    });

    test('descarta una verificación vieja que termina tarde', () async {
      final lenta = Completer<bool>();
      when(() => coordinador.verificarCosto(tienda, aceite, d('1')))
          .thenAnswer((_) => lenta.future);
      await vm.elegirProducto(aceite);

      final vieja = vm.cambiarCosto('1');
      await vm.cambiarCosto('2');
      lenta.complete(true);
      await vieja;

      expect(vm.costoDifiere, isFalse);
    });

    test('elegir el producto después del costo también verifica', () async {
      when(() => coordinador.verificarCosto(tienda, aceite, d('9400')))
          .thenAnswer((_) async => true);
      await vm.cambiarCosto('9400');

      await vm.elegirProducto(aceite);

      expect(vm.costoDifiere, isTrue);
    });
  });

  group('registrar', () {
    test('muestra el nuevo stock y limpia cantidad y costo', () async {
      when(
        () => coordinador.registrarEntrada(
          tienda,
          aceite,
          d('24'),
          d('9400'),
          'FV-1',
        ),
      ).thenAnswer((_) async => entradaCon('32'));
      await vm.elegirProducto(aceite);
      vm.cambiarCantidad('24');
      await vm.cambiarCosto('9.400');

      expect(await vm.registrar('FV-1'), isTrue);

      expect(vm.aviso, 'Entrada registrada. Nuevo stock: 32');
      expect(vm.error, isNull);
      expect(vm.cantidad, isNull);
      expect(vm.costo, isNull);
      expect(vm.producto, aceite);
      expect(vm.registrando, isFalse);
    });

    test('registra aunque el costo difiera (no bloquea)', () async {
      when(() => coordinador.verificarCosto(any(), any(), any()))
          .thenAnswer((_) async => true);
      when(
        () => coordinador.registrarEntrada(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => entradaCon('32'));
      await vm.elegirProducto(aceite);
      vm.cambiarCantidad('24');
      await vm.cambiarCosto('9400');
      expect(vm.costoDifiere, isTrue);

      expect(await vm.registrar(''), isTrue);
      expect(vm.costoDifiere, isFalse);
    });

    test('muestra el stock con decimales a la colombiana', () async {
      when(
        () => coordinador.registrarEntrada(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => entradaCon('10.5'));
      await vm.elegirProducto(aceite);
      vm.cambiarCantidad('2,5');
      await vm.cambiarCosto('3000');

      await vm.registrar('');
      expect(vm.aviso, 'Entrada registrada. Nuevo stock: 10,5');
    });

    test('sin producto pide elegirlo y no llama al coordinador', () async {
      vm.cambiarCantidad('1');
      await vm.cambiarCosto('1');
      expect(await vm.registrar(''), isFalse);
      expect(vm.error, 'Elija el producto que llegó');
      verifyNever(
        () => coordinador.registrarEntrada(any(), any(), any(), any(), any()),
      );
    });

    test('sin cantidad o sin costo lo pide', () async {
      await vm.elegirProducto(aceite);
      await vm.cambiarCosto('1');
      expect(await vm.registrar(''), isFalse);
      expect(vm.error, 'Escriba cuántas unidades llegaron');

      vm.cambiarCantidad('1');
      await vm.cambiarCosto('');
      expect(await vm.registrar(''), isFalse);
      expect(vm.error, 'Escriba el costo por unidad');
    });

    test('muestra el mensaje del error de negocio', () async {
      when(
        () => coordinador.registrarEntrada(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => throw const ExcepcionDatosEntradaNoValidos());
      await vm.elegirProducto(aceite);
      vm.cambiarCantidad('0');
      await vm.cambiarCosto('100');

      expect(await vm.registrar(''), isFalse);
      expect(
        vm.error,
        'La cantidad debe ser mayor que cero y el costo no puede ser negativo',
      );
      expect(vm.cantidad, Decimal.zero);
    });

    test('si falla el guardado muestra el mensaje del diagrama', () async {
      when(
        () => coordinador.registrarEntrada(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => throw StateError('disco'));
      await vm.elegirProducto(aceite);
      vm.cambiarCantidad('24');
      await vm.cambiarCosto('9400');

      expect(await vm.registrar(''), isFalse);
      expect(vm.error, 'No se pudo registrar la entrada. Intente de nuevo');
      expect(vm.cantidad, d('24'));
      expect(vm.registrando, isFalse);
    });
  });
}
