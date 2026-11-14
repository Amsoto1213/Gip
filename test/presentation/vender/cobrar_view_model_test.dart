import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/presentation/vender/cobrar_view_model.dart';

import 'venta_de_prueba.dart';

void main() {
  late VentaDePrueba prueba;

  setUp(() async => prueba = await VentaDePrueba.crear());

  /// Cobrar con [cantidades] de arroz ($ 2.800) y café ($ 8.900).
  Future<CobrarViewModel> cobrar({int arroz = 0, int cafe = 0}) async {
    final lineas = <LineaVenta>[];
    if (arroz > 0) {
      await prueba.coordinador.agregarProducto(
        tiendaPrueba,
        lineas,
        prueba.arroz,
        d('$arroz'),
      );
    }
    if (cafe > 0) {
      await prueba.coordinador.agregarProducto(
        tiendaPrueba,
        lineas,
        prueba.cafe,
        d('$cafe'),
      );
    }
    return CobrarViewModel(
      prueba.coordinador,
      tiendaPrueba,
      lineas,
      prueba.coordinador.obtenerTotal(lineas),
    );
  }

  test('efectivo: calcula el cambio y completa el pago', () async {
    final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
    vm.cambiarEfectivo('20.000');

    expect(vm.contado!.getCambio(), d('5500'));
    expect(vm.pagoCompleto, isTrue);
    expect(vm.errorEfectivo, isNull);
  });

  test('"El monto recibido no alcanza"', () async {
    final vm = await cobrar(arroz: 2, cafe: 1);
    vm.cambiarEfectivo('10.000');

    expect(vm.contado, isNull);
    expect(vm.errorEfectivo, 'El monto recibido no alcanza');
    expect(vm.pagoCompleto, isFalse);
  });

  test('sugerencias: justo y billetes que lo superan', () async {
    final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
    expect(vm.sugerenciasEfectivo, [
      d('14500'),
      d('15000'),
      d('20000'),
      d('50000'),
    ]);
  });

  test('mixto: el efectivo cubre lo que falta después de Nequi', () async {
    final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
    vm.cambiarEfectivo('10.000');
    expect(vm.errorEfectivo, 'El monto recibido no alcanza');

    vm.cambiarNequi('5.000', '4471');
    expect(vm.efectivoACubrir, d('9500'));
    expect(vm.contado!.getCambio(), d('500'));
    expect(vm.contado!.calcularMontoCubierto(), d('9500'));
    expect(vm.pagoCompleto, isTrue);

    vm.quitarNequi();
    expect(vm.contado, isNull);
    expect(vm.errorEfectivo, 'El monto recibido no alcanza');
  });

  test('solo Nequi por el total', () async {
    final vm = await cobrar(arroz: 1);
    vm.cambiarNequi('2.800', '');

    expect(vm.nequi!.getReferencia(), isNull);
    expect(vm.formasPago, [vm.nequi]);
    expect(vm.pagoCompleto, isTrue);
    expect(vm.sugerenciasEfectivo, isEmpty);
  });

  test('Nequi en cero muestra el error del servicio', () async {
    final vm = await cobrar(arroz: 1);
    vm.cambiarNequi('0', '');

    expect(vm.nequi, isNull);
    expect(vm.errorNequi, 'El monto debe ser mayor que cero');
  });

  test(
    'confirmar registra la venta y la caja recibe el monto cubierto',
    () async {
      final vm = await cobrar(arroz: 2, cafe: 1);
      vm.cambiarEfectivo('50.000');

      expect(await vm.confirmar(), isTrue);
      expect(vm.error, isNull);
      expect(prueba.ventas.de(tiendaPrueba), hasLength(1));
      expect(
        prueba.cajas.movimientosDe(tiendaPrueba).single.getValor(),
        d('14500'),
      );
    },
  );

  test(
    'confirmar con pago incompleto muestra el mensaje del diagrama',
    () async {
      final vm = await cobrar(arroz: 2, cafe: 1);
      vm.cambiarNequi('5.000', '');

      expect(await vm.confirmar(), isFalse);
      expect(vm.error, 'Las formas de pago no cubren el total de la venta');
      expect(prueba.ventas.datos, isEmpty);
    },
  );

  test('si falla al guardar: "No se pudo registrar la venta"', () async {
    final vm = await cobrar(arroz: 1);
    vm.cambiarEfectivo('5.000');
    prueba.cajas.fallar = true;

    expect(await vm.confirmar(), isFalse);
    expect(vm.error, 'No se pudo registrar la venta. Intente de nuevo');
    expect(prueba.ventas.datos[tiendaPrueba.getId()] ?? [], isEmpty);
  });
}
