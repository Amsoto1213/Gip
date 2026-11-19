import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/presentation/negocio/exportar_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_exportacion.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_alertas.dart';
import 'exportar_falsos.dart';

void main() {
  late ExportarDatosFalso coordinador;
  // Domingo 15 de noviembre de 2026.
  final ahora = DateTime(2026, 11, 15, 9, 30);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(FormatoExportacion.excel);
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = ExportarDatosFalso());

  ExportarViewModel crear({bool propietaria = true}) => ExportarViewModel(
    coordinador,
    propietaria ? propietariaAlertas : empleadoAlertas,
    reloj: () => ahora,
  );

  When<Future<String>> alExportar() =>
      when(() => coordinador.exportar(any(), any(), any(), any(), any()));

  test('empieza en el mes actual, hasta hoy, en Excel', () {
    final vm = crear();

    expect(vm.desde, DateTime(2026, 11));
    expect(vm.ultimoDia, DateTime(2026, 11, 15));
    expect(vm.hoy, DateTime(2026, 11, 15));
    expect(vm.formato, FormatoExportacion.excel);
    expect(vm.exportando, isFalse);
    expect(vm.error, isNull);
    expect(vm.mensajeListo, isNull);
    expect(vm.puedeExportar, isTrue);
  });

  test('exporta con el día siguiente al último como hasta (DI-28)', () async {
    alExportar().thenAnswer((_) async => 'gip-2026-10-01_a_2026-10-31.xlsx');
    final vm = crear()
      ..elegirDesde(DateTime(2026, 10, 1, 14))
      ..elegirHasta(DateTime(2026, 10, 31, 8));

    await vm.exportar();

    final args = verify(
      () => coordinador.exportar(
        captureAny(),
        captureAny(),
        captureAny(),
        captureAny(),
        captureAny(),
      ),
    ).captured;
    expect(args[0], tiendaAlertas);
    expect(args[1], DateTime(2026, 10, 1));
    expect(args[2], DateTime(2026, 11, 1));
    expect(args[3], FormatoExportacion.excel);
    expect(args[4], propietariaAlertas.usuario);
    expect(
      vm.mensajeListo,
      'Datos exportados: gip-2026-10-01_a_2026-10-31.xlsx',
    );
    expect(vm.error, isNull);
    expect(vm.exportando, isFalse);
  });

  test('el último día del mes pasa al día 1 del siguiente', () async {
    alExportar().thenAnswer((_) async => 'x');
    final vm = crear()..elegirHasta(DateTime(2026, 12, 31));

    await vm.exportar();

    final args = verify(
      () => coordinador.exportar(any(), any(), captureAny(), any(), any()),
    ).captured;
    expect(args.single, DateTime(2027));
  });

  test('en CSV el mensaje dice que son tres archivos', () async {
    alExportar().thenAnswer((_) async => 'gip-2026-11-01_a_2026-11-15');
    final vm = crear()..elegirFormato(FormatoExportacion.csv);

    await vm.exportar();

    expect(
      vm.mensajeListo,
      'Datos exportados: gip-2026-11-01_a_2026-11-15 (3 archivos CSV)',
    );
    final formato = verify(
      () => coordinador.exportar(any(), any(), any(), captureAny(), any()),
    ).captured.single;
    expect(formato, FormatoExportacion.csv);
  });

  test('hasta antes de desde: avisa y no exporta', () async {
    final vm = crear()
      ..elegirDesde(DateTime(2026, 11, 10))
      ..elegirHasta(DateTime(2026, 11, 9));

    expect(
      vm.errorPeriodo,
      'La fecha inicial no puede ser posterior a la final',
    );
    expect(vm.puedeExportar, isFalse);
    await vm.exportar();

    verifyNever(() => coordinador.exportar(any(), any(), any(), any(), any()));
  });

  test('un solo día (desde = hasta) es válido', () async {
    alExportar().thenAnswer((_) async => 'x');
    final vm = crear()
      ..elegirDesde(DateTime(2026, 11, 10))
      ..elegirHasta(DateTime(2026, 11, 10));

    expect(vm.errorPeriodo, isNull);
    await vm.exportar();

    final args = verify(
      () =>
          coordinador.exportar(any(), captureAny(), captureAny(), any(), any()),
    ).captured;
    expect(args, [DateTime(2026, 11, 10), DateTime(2026, 11, 11)]);
  });

  test(
    'el periodo no válido del servicio se muestra con el mismo texto',
    () async {
      alExportar().thenThrow(const ExcepcionPeriodoNoValido());
      final vm = crear();

      await vm.exportar();

      expect(vm.error, 'La fecha inicial no puede ser posterior a la final');
      expect(vm.mensajeListo, isNull);
    },
  );

  test('el empleado ve el mensaje de solo propietario', () async {
    alExportar().thenThrow(const ExcepcionSoloPropietario());
    final vm = crear(propietaria: false);

    await vm.exportar();

    expect(vm.error, 'Esta consulta es solo para el propietario');
    expect(vm.exportando, isFalse);
  });

  test('una falla inesperada da un mensaje para el tendero', () async {
    alExportar().thenThrow(StateError('x'));
    final vm = crear();

    await vm.exportar();

    expect(vm.error, 'No se pudo exportar. Intente de nuevo');
    expect(vm.mensajeListo, isNull);
    expect(vm.exportando, isFalse);
  });

  test('mientras exporta no deja exportar otra vez', () async {
    final espera = Completer<String>();
    alExportar().thenAnswer((_) => espera.future);
    final vm = crear();

    final primera = vm.exportar();
    expect(vm.exportando, isTrue);
    expect(vm.puedeExportar, isFalse);
    await vm.exportar();
    espera.complete('listo.xlsx');
    await primera;

    verify(() => coordinador.exportar(any(), any(), any(), any(), any()))
        .called(1);
    expect(vm.exportando, isFalse);
  });

  test('cambiar una fecha o el formato borra el resultado anterior', () async {
    alExportar().thenAnswer((_) async => 'x.xlsx');
    final vm = crear();
    await vm.exportar();
    expect(vm.mensajeListo, isNotNull);

    vm.elegirFormato(FormatoExportacion.csv);
    expect(vm.mensajeListo, isNull);

    await vm.exportar();
    expect(vm.mensajeListo, isNotNull);
    vm.elegirDesde(DateTime(2026, 11, 2));
    expect(vm.mensajeListo, isNull);
  });

  test('tras un error, una exportación buena lo limpia', () async {
    alExportar().thenThrow(StateError('x'));
    final vm = crear();
    await vm.exportar();
    expect(vm.error, isNotNull);

    alExportar().thenAnswer((_) async => 'bien.xlsx');
    await vm.exportar();

    expect(vm.error, isNull);
    expect(vm.mensajeListo, 'Datos exportados: bien.xlsx');
  });
}
