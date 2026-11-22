import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
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
    expect(guardadas.single.getProductoId(), prueba.queso.getId());
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

  group('cantidades por peso (DI-53)', () {
    test('agregar un producto por kilo empieza en 1 kg', () async {
      await vm.agregar(prueba.yuca);

      expect(vm.lineas.single.getCantidad(), d('1'));
      expect(vm.total, d('3000'));
    });

    test('cambiarCantidad acepta decimales y actualiza el total', () async {
      await vm.agregar(prueba.yuca);

      await vm.cambiarCantidad(vm.lineas.single, d('3.4'));

      expect(vm.lineas.single.getCantidad(), d('3.4'));
      expect(vm.total, d('10200'));
      expect(vm.error, isNull);
    });

    test(
      'cambiarCantidad sin existencia deja la cantidad y avisa (RN-01)',
      () async {
        await vm.agregar(prueba.yuca);
        final linea = vm.lineas.single;

        await vm.cambiarCantidad(linea, d('12.5'));

        expect(linea.getCantidad(), d('1'));
        expect(vm.error, 'No hay suficiente existencia del producto');
        expect(vm.productoSinExistencia, prueba.yuca);
      },
    );

    test('+ y − siguen sumando y restando de a uno con decimales', () async {
      await vm.agregar(prueba.yuca);
      final linea = vm.lineas.single;
      await vm.cambiarCantidad(linea, d('3.4'));

      await vm.sumar(linea);
      expect(linea.getCantidad(), d('4.4'));
      await vm.restar(linea);
      await vm.restar(linea);
      expect(linea.getCantidad(), d('2.4'));
    });

    test('− con menos de uno quita la línea', () async {
      await vm.agregar(prueba.yuca);
      final linea = vm.lineas.single;
      await vm.cambiarCantidad(linea, d('0.4'));

      await vm.restar(linea);

      expect(vm.lineas, isEmpty);
    });

    test('admiteDecimales: kilos y libras sí, unidad no', () {
      expect(VenderViewModel.admiteDecimales(UnidadMedida.kilogramo), isTrue);
      expect(VenderViewModel.admiteDecimales(UnidadMedida.libra), isTrue);
      expect(VenderViewModel.admiteDecimales(UnidadMedida.unidad), isFalse);
    });

    for (final (texto, unidad, error) in <(String, UnidadMedida, String?)>[
      ('3,4', UnidadMedida.kilogramo, null),
      ('3.4', UnidadMedida.kilogramo, null),
      (' 3,4 ', UnidadMedida.libra, null),
      ('0,125', UnidadMedida.kilogramo, null),
      ('3', UnidadMedida.kilogramo, null),
      ('3', UnidadMedida.unidad, null),
      ('12', UnidadMedida.unidad, null),
      ('', UnidadMedida.kilogramo, 'Escriba la cantidad'),
      ('abc', UnidadMedida.kilogramo, 'Escriba la cantidad'),
      ('-2', UnidadMedida.kilogramo, 'Escriba la cantidad'),
      ('3,', UnidadMedida.kilogramo, 'Escriba la cantidad'),
      ('0', UnidadMedida.kilogramo, 'La cantidad debe ser mayor que cero'),
      ('0,0', UnidadMedida.libra, 'La cantidad debe ser mayor que cero'),
      (
        '2,5',
        UnidadMedida.unidad,
        'Este producto se vende por unidad: escriba un número entero',
      ),
      ('1,2345', UnidadMedida.kilogramo, 'Use máximo 3 decimales'),
    ]) {
      test('errorDeCantidad("$texto", ${unidad.name}) → $error', () {
        expect(VenderViewModel.errorDeCantidad(texto, unidad), error);
        expect(
          VenderViewModel.leerCantidad(texto, unidad) == null,
          error != null,
        );
      });
    }

    test('leerCantidad entiende la coma y el punto', () {
      expect(
        VenderViewModel.leerCantidad('3,4', UnidadMedida.kilogramo),
        d('3.4'),
      );
      expect(
        VenderViewModel.leerCantidad('3.4', UnidadMedida.kilogramo),
        d('3.4'),
      );
    });
  });
}
