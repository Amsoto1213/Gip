import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/caja/cierre_caja_view_model.dart';
import 'package:gip/presentation/comun/tarjeta_diferencia.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:mocktail/mocktail.dart';

import 'caja_falsos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');
  Decimal d(String v) => Decimal.parse(v);

  late RegistrarCierreCajaFalso coordinador;
  late CierreCajaViewModel vm;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(propietario);
    registerFallbackValue(Decimal.zero);
  });

  setUp(() {
    coordinador = RegistrarCierreCajaFalso();
    vm = CierreCajaViewModel(coordinador, (
      usuario: propietario,
      tienda: tienda,
    ));
    when(() => coordinador.consultarSaldoEsperado(any(), any()))
        .thenAnswer((_) async => d('318500'));
  });

  When<Future<Decimal>> cuandoCierra() =>
      when(() => coordinador.cerrarCaja(any(), any(), any()));

  group('cargar', () {
    test('trae lo que debe haber con la tienda y el usuario activo', () async {
      await vm.cargar();

      expect(vm.saldoEsperado, d('318500'));
      expect(vm.cargando, isFalse);
      verify(() => coordinador.consultarSaldoEsperado(tienda, propietario))
          .called(1);
    });

    test('un empleado recibe el rechazo de acceso', () async {
      when(() => coordinador.consultarSaldoEsperado(any(), any()))
          .thenThrow(const ExcepcionSoloPropietario());

      await vm.cargar();

      expect(vm.saldoEsperado, isNull);
      expect(vm.error, 'Solo el propietario de la tienda puede hacer esto');
    });

    test('un fallo inesperado da un mensaje para el tendero', () async {
      when(() => coordinador.consultarSaldoEsperado(any(), any()))
          .thenThrow(StateError('disco'));

      await vm.cargar();

      expect(vm.error, 'No se pudo consultar la caja. Inténtalo de nuevo');
    });
  });

  group('vista previa', () {
    setUp(() => vm.cargar());

    test('menos efectivo del esperado es un faltante', () {
      vm.escribirEfectivo('315.000');

      expect(vm.efectivoContado, d('315000'));
      expect(vm.vistaPrevia, d('-3500'));
      expect(
        CierreCajaViewModel.tonoDe(vm.vistaPrevia!),
        TonoDiferencia.faltante,
      );
    });

    test('más efectivo es un sobrante y el mismo es "cuadra"', () {
      vm.escribirEfectivo('320.000');
      expect(vm.vistaPrevia, d('1500'));
      expect(
        CierreCajaViewModel.tonoDe(vm.vistaPrevia!),
        TonoDiferencia.sobrante,
      );

      vm.escribirEfectivo('318.500');
      expect(vm.vistaPrevia, Decimal.zero);
      expect(
        CierreCajaViewModel.tonoDe(vm.vistaPrevia!),
        TonoDiferencia.cuadra,
      );
    });

    test('vacío, no numérico o negativo no tienen vista previa', () {
      for (final texto in ['', 'abc', '-5']) {
        vm.escribirEfectivo(texto);
        expect(vm.efectivoContado, isNull, reason: texto);
        expect(vm.vistaPrevia, isNull, reason: texto);
      }
    });

    test('cero es un efectivo válido (caja vacía)', () {
      vm.escribirEfectivo('0');
      expect(vm.efectivoContado, Decimal.zero);
      expect(vm.vistaPrevia, d('-318500'));
    });

    test('los textos de la diferencia', () {
      expect(CierreCajaViewModel.tituloDe(d('-3500')), 'Faltan');
      expect(CierreCajaViewModel.montoDe(d('-3500')), r'$ 3.500');
      expect(CierreCajaViewModel.tituloDe(d('1500')), 'Sobran');
      expect(CierreCajaViewModel.montoDe(d('1500')), r'$ 1.500');
      expect(CierreCajaViewModel.tituloDe(Decimal.zero), 'La caja cuadra');
      expect(CierreCajaViewModel.montoDe(Decimal.zero), isNull);
    });
  });

  group('cerrar', () {
    setUp(() => vm.cargar());

    test('cierra con el efectivo escrito y guarda la diferencia', () async {
      cuandoCierra().thenAnswer((_) async => d('-3500'));

      final ok = await vm.cerrar('315.000');

      expect(ok, isTrue);
      expect(vm.cerrada, isTrue);
      expect(vm.diferenciaFinal, d('-3500'));
      verify(() => coordinador.cerrarCaja(tienda, d('315000'), propietario))
          .called(1);
    });

    test('un efectivo no válido no llama al coordinador', () async {
      for (final texto in ['', 'abc', '-1']) {
        expect(await vm.cerrar(texto), isFalse, reason: texto);
        expect(vm.error, 'Escribe cuánto efectivo contó', reason: texto);
      }
      verifyNever(() => coordinador.cerrarCaja(any(), any(), any()));
      expect(vm.cerrada, isFalse);
    });

    test('una caja ya cerrada muestra el mensaje del diagrama', () async {
      cuandoCierra().thenThrow(const ExcepcionCajaCerrada());

      expect(await vm.cerrar('1.000'), isFalse);

      expect(vm.error, 'La caja de hoy ya está cerrada');
      expect(vm.cerrada, isFalse);
    });

    test('un fallo inesperado da un mensaje para el tendero', () async {
      cuandoCierra().thenThrow(StateError('disco'));

      await vm.cerrar('1.000');

      expect(vm.error, 'No se pudo cerrar la caja. Inténtalo de nuevo');
      expect(vm.cerrando, isFalse);
    });

    test(
      'una vez cerrada no se vuelve a cerrar ni a cambiar el efectivo',
      () async {
        cuandoCierra().thenAnswer((_) async => Decimal.zero);
        await vm.cerrar('318.500');

        expect(await vm.cerrar('1'), isFalse);
        vm.escribirEfectivo('1');

        expect(vm.efectivoContado, d('318500'));
        verify(() => coordinador.cerrarCaja(any(), any(), any())).called(1);
      },
    );
  });
}
