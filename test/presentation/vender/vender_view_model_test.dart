import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/vender/vender_view_model.dart';

import 'venta_de_prueba.dart';

void main() {
  late VentaDePrueba prueba;
  late VenderViewModel vm;

  setUp(() async {
    prueba = await VentaDePrueba.crear();
    vm = VenderViewModel(
      prueba.coordinador,
      prueba.coordinadorPerdida,
      tiendaPrueba,
    );
  });
  tearDown(() => vm.dispose());

  test('agregar crea la línea con una unidad y actualiza el total', () async {
    await vm.agregar(prueba.arroz);
    await vm.agregar(prueba.cafe);

    expect(vm.lineas, hasLength(2));
    expect(vm.total, d('11700'));
    expect(vm.error, isNull);
  });

  test('agregar el mismo producto suma en su línea', () async {
    await vm.agregar(prueba.arroz);
    await vm.agregar(prueba.arroz);

    expect(vm.lineas.single.getCantidad(), d('2'));
    expect(vm.total, d('5600'));
  });

  test('sin existencia muestra el mensaje y no agrega (RN-01)', () async {
    await vm.agregar(prueba.queso);

    expect(vm.lineas, isEmpty);
    expect(vm.error, 'No hay suficiente existencia del producto');
    expect(vm.total, Decimal.zero);
  });

  test('+ y − cambian la cantidad; − en 1 quita la línea', () async {
    await vm.agregar(prueba.arroz);
    final linea = vm.lineas.single;

    await vm.sumar(linea);
    expect(linea.getCantidad(), d('2'));
    expect(vm.total, d('5600'));

    await vm.restar(linea);
    expect(linea.getCantidad(), d('1'));

    await vm.restar(linea);
    expect(vm.lineas, isEmpty);
    expect(vm.total, Decimal.zero);
  });

  test('+ sin existencia deja la cantidad y muestra el error', () async {
    await vm.agregar(prueba.arroz);
    final linea = vm.lineas.single;
    for (var i = 0; i < 9; i++) {
      await vm.sumar(linea);
    }
    expect(linea.getCantidad(), d('10'));

    await vm.sumar(linea);
    expect(linea.getCantidad(), d('10'));
    expect(vm.error, 'No hay suficiente existencia del producto');
  });

  test('vaciar descarta la venta sin guardar nada', () async {
    await vm.agregar(prueba.arroz);
    vm.vaciar();

    expect(vm.lineas, isEmpty);
    expect(vm.total, Decimal.zero);
    expect(prueba.ventas.datos, isEmpty);
  });

  test('ventaRegistrada deja la venta en blanco con el aviso', () async {
    await vm.agregar(prueba.arroz);
    vm.ventaRegistrada();

    expect(vm.lineas, isEmpty);
    expect(vm.aviso, 'Venta registrada');
  });

  test('sin existencia ofrece anotar la venta perdida (CUS-13)', () async {
    await vm.agregar(prueba.queso);
    expect(vm.productoSinExistencia, prueba.queso);

    await vm.registrarVentaPerdida();

    expect(vm.aviso, 'Venta perdida registrada');
    expect(vm.error, isNull);
    expect(vm.productoSinExistencia, isNull);
    expect(vm.lineas, isEmpty);
    final guardadas = prueba.perdidas.datos[tiendaPrueba.getId()]!;
    expect(guardadas.single.getProducto(), prueba.queso);
  });

  test('otro error o un producto con existencia no ofrece anotarla', () async {
    await vm.agregar(prueba.arroz);

    expect(vm.productoSinExistencia, isNull);
    await vm.registrarVentaPerdida();
    expect(prueba.perdidas.datos, isEmpty);
  });

  test('seguir vendiendo quita el botón de venta perdida', () async {
    await vm.agregar(prueba.queso);
    await vm.agregar(prueba.arroz);

    expect(vm.productoSinExistencia, isNull);
  });
}
