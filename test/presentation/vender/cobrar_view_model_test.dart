import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
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

  group('fiado (CUS-07)', () {
    final maria = Cliente('c1', 'María Pérez', '');

    test(
      'fiado solo: completa el pago, guarda el fiado y no toca la caja',
      () async {
        final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
        final datos = vm.datosFiar;
        expect(datos.yaPago, d('0'));
        expect(datos.falta, d('14500'));
        expect(datos.detallePagado, 'nada aún');

        vm.agregarFiado(
          prueba.registrarFiado.prepararFiado(maria, datos.falta),
        );
        expect(vm.pagoCompleto, isTrue);
        expect(vm.efectivoACubrir, d('0'));

        expect(await vm.confirmar(), isTrue);
        expect(
          prueba.fiados.de(tiendaPrueba).single.getMontoInicial(),
          d('14500'),
        );
        expect(prueba.cajas.movimientos, isEmpty);
      },
    );

    test('efectivo que no alcanza + fiado de lo que falta: el efectivo '
        'queda justo y solo él entra a la caja', () async {
      final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
      vm.cambiarEfectivo('5.000');
      expect(vm.errorEfectivo, 'El monto recibido no alcanza');

      final datos = vm.datosFiar;
      expect(datos.yaPago, d('5000'));
      expect(datos.falta, d('9500'));
      expect(datos.detallePagado, 'efectivo');

      vm.agregarFiado(prueba.registrarFiado.prepararFiado(maria, datos.falta));
      expect(vm.errorEfectivo, isNull);
      expect(vm.contado!.getCambio(), d('0'));
      expect(vm.formasPago, hasLength(2));
      expect(vm.pagoCompleto, isTrue);

      expect(await vm.confirmar(), isTrue);
      expect(
        prueba.cajas.movimientosDe(tiendaPrueba).single.getValor(),
        d('5000'),
      );
      expect(prueba.fiados.de(tiendaPrueba), hasLength(1));
    });

    test('Nequi + fiado: no mueve la caja', () async {
      final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
      vm.cambiarNequi('10.000', '');
      final datos = vm.datosFiar;
      expect(datos.detallePagado, 'Nequi');
      expect(datos.falta, d('4500'));

      vm.agregarFiado(prueba.registrarFiado.prepararFiado(maria, datos.falta));

      expect(await vm.confirmar(), isTrue);
      expect(prueba.cajas.movimientos, isEmpty);
      expect(prueba.fiados.de(tiendaPrueba), hasLength(1));
    });

    test(
      'las tres formas, y quitar el fiado vuelve a pedir el efectivo',
      () async {
        final vm = await cobrar(arroz: 2, cafe: 1); // 14.500
        vm.cambiarNequi('4.500', '');
        vm.cambiarEfectivo('5.000');
        expect(vm.datosFiar.detallePagado, 'efectivo y Nequi');
        vm.agregarFiado(prueba.registrarFiado.prepararFiado(maria, d('5000')));
        expect(vm.formasPago, hasLength(3));
        expect(vm.pagoCompleto, isTrue);

        vm.quitarFiado();
        expect(vm.fiado, isNull);
        expect(vm.errorEfectivo, 'El monto recibido no alcanza');
        expect(vm.pagoCompleto, isFalse);
      },
    );

    test('un fiado mayor que lo que falta: los pagos pasan el total y no se '
        'confirma', () async {
      final vm = await cobrar(arroz: 1); // 2.800
      vm.cambiarNequi('2.000', '');
      vm.agregarFiado(prueba.registrarFiado.prepararFiado(maria, d('1000')));

      expect(vm.faltante, d('-200'));
      expect(vm.pagoCompleto, isFalse);
      expect(await vm.confirmar(), isFalse);
      expect(vm.error, 'Las formas de pago no cubren el total de la venta');
      expect(prueba.fiados.datos[tiendaPrueba.getId()] ?? [], isEmpty);
    });

    test('si falla al guardar el fiado: no queda venta ni fiado', () async {
      final vm = await cobrar(arroz: 1);
      vm.agregarFiado(prueba.registrarFiado.prepararFiado(maria, d('2800')));
      prueba.fiados.fallar = true;

      expect(await vm.confirmar(), isFalse);
      expect(vm.error, 'No se pudo registrar la venta. Intente de nuevo');
      expect(prueba.ventas.datos[tiendaPrueba.getId()] ?? [], isEmpty);
      expect(prueba.fiados.datos[tiendaPrueba.getId()] ?? [], isEmpty);
    });
  });
}
