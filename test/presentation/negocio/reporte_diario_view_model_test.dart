import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/presentation/negocio/reporte_diario_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_alertas.dart';
import 'reporte_falsos.dart';

void main() {
  late GenerarReporteDiarioFalso coordinador;
  // Domingo 15 de noviembre de 2026.
  final ahora = DateTime(2026, 11, 15, 9, 30);
  final hoy = DateTime(2026, 11, 15);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(hoy);
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = GenerarReporteDiarioFalso());

  ReporteDiarioViewModel crear({bool propietaria = true}) =>
      ReporteDiarioViewModel(
        coordinador,
        propietaria ? propietariaAlertas : empleadoAlertas,
        reloj: () => ahora,
      );

  ReporteDiario reporte({String ventas = '0', String entradas = '0'}) =>
      ReporteDiario(
        hoy,
        d(ventas),
        d('0'),
        d('0'),
        d('0'),
        d('0'),
        d(entradas),
        d('0'),
        d('0'),
        d('0'),
        false,
        false,
      );

  void responder(ReporteDiario r) =>
      when(() => coordinador.generarReporte(any(), any(), any()))
          .thenAnswer((_) async => r);

  DateTime ultimaFecha() =>
      verify(() => coordinador.generarReporte(any(), captureAny(), any()))
              .captured
              .last
          as DateTime;

  test('empieza en hoy y genera el reporte de hoy', () async {
    responder(reporte(ventas: '5000'));
    final vm = crear();

    await vm.cargar();

    expect(vm.fecha, hoy);
    expect(vm.esHoy, isTrue);
    expect(vm.puedeAvanzar, isFalse);
    expect(vm.reporte!.getTotalVentas(), d('5000'));
    expect(vm.error, isNull);
    expect(vm.cargando, isFalse);
    expect(ultimaFecha(), hoy);
  });

  test('día anterior y día siguiente cambian la fecha y regeneran', () async {
    responder(reporte());
    final vm = crear();

    await vm.irDiaAnterior();
    expect(vm.fecha, DateTime(2026, 11, 14));
    expect(vm.esHoy, isFalse);
    expect(vm.puedeAvanzar, isTrue);
    expect(ultimaFecha(), DateTime(2026, 11, 14));

    await vm.irDiaSiguiente();
    expect(vm.fecha, hoy);
    expect(ultimaFecha(), hoy);
  });

  test(
    'no pasa de hoy: siguiente no hace nada y una fecha futura va a hoy',
    () async {
      responder(reporte());
      final vm = crear();

      await vm.irDiaSiguiente();
      verifyNever(() => coordinador.generarReporte(any(), any(), any()));

      await vm.elegirFecha(DateTime(2026, 12, 1, 15));
      expect(vm.fecha, hoy);
    },
  );

  test('elegirFecha usa el día sin la hora', () async {
    responder(reporte());
    final vm = crear();

    await vm.elegirFecha(DateTime(2026, 11, 3, 18, 45));

    expect(vm.fecha, DateTime(2026, 11, 3));
    expect(ultimaFecha(), DateTime(2026, 11, 3));
  });

  test('sinMovimiento es verdadero solo si todo está en cero', () async {
    responder(reporte());
    final vm = crear();
    await vm.cargar();
    expect(vm.sinMovimiento, isTrue);

    responder(reporte(entradas: '100'));
    await vm.cargar();
    expect(vm.sinMovimiento, isFalse);
  });

  test('el empleado recibe el mensaje de solo propietario', () async {
    when(() => coordinador.generarReporte(any(), any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());
    final vm = crear(propietaria: false);

    await vm.cargar();

    expect(vm.error, ReporteDiarioViewModel.mensajeSoloPropietario);
    expect(vm.reporte, isNull);
  });

  test('una falla inesperada da un mensaje para el tendero', () async {
    when(() => coordinador.generarReporte(any(), any(), any()))
        .thenThrow(StateError('disco'));
    final vm = crear();

    await vm.cargar();

    expect(vm.error, 'No se pudo generar el reporte. Intente de nuevo');
    expect(vm.cargando, isFalse);
  });

  test(
    'si llegan dos respuestas, solo cuenta la de la última consulta',
    () async {
      final lenta = Completer<ReporteDiario>();
      var llamadas = 0;
      when(() => coordinador.generarReporte(any(), any(), any()))
          .thenAnswer((_) {
            llamadas++;
            return llamadas == 1
                ? lenta.future
                : Future.value(reporte(ventas: '2'));
          });
      final vm = crear();

      final primera = vm.cargar();
      await vm.cargar();
      lenta.complete(reporte(ventas: '1'));
      await primera;

      expect(vm.reporte!.getTotalVentas(), Decimal.parse('2'));
    },
  );
}
