import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/presentation/negocio/margen_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_alertas.dart';
import 'margen_falsos.dart';

void main() {
  late ConsultarMargenFalso coordinador;
  // Domingo 15 de noviembre de 2026.
  final ahora = DateTime(2026, 11, 15, 9, 30);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = ConsultarMargenFalso());

  MargenViewModel crear({bool propietaria = true}) => MargenViewModel(
    coordinador,
    propietaria ? propietariaAlertas : empleadoAlertas,
    reloj: () => ahora,
  );

  void responder(Map<Producto, Decimal?> margenes) =>
      when(() => coordinador.consultarMargen(any(), any(), any(), any()))
          .thenAnswer((_) async => margenes);

  (DateTime, DateTime) ultimoPeriodo() {
    final args = verify(
      () =>
          coordinador.consultarMargen(any(), captureAny(), captureAny(), any()),
    ).captured;
    return (args[0] as DateTime, args[1] as DateTime);
  }

  test('empieza en la semana: últimos 7 días contando hoy', () async {
    responder({});
    final vm = crear();

    await vm.cargar();

    expect(vm.periodo, PeriodoMargen.semana);
    expect(ultimoPeriodo(), (DateTime(2026, 11, 9), DateTime(2026, 11, 16)));
    expect(vm.desde, DateTime(2026, 11, 9));
    expect(vm.ultimoDia, DateTime(2026, 11, 15));
  });

  test('hoy y mes consultan su periodo', () async {
    responder({});
    final vm = crear();

    await vm.elegirPeriodo(PeriodoMargen.hoy);
    expect(ultimoPeriodo(), (DateTime(2026, 11, 15), DateTime(2026, 11, 16)));

    await vm.elegirPeriodo(PeriodoMargen.mes);
    expect(ultimoPeriodo(), (DateTime(2026, 11, 1), DateTime(2026, 11, 16)));
  });

  test('un rango de fechas incluye el último día', () async {
    responder({});
    final vm = crear();

    await vm.elegirFechas(DateTime(2026, 11, 5), DateTime(2026, 11, 11));

    expect(vm.periodo, PeriodoMargen.fechas);
    expect(ultimoPeriodo(), (DateTime(2026, 11, 5), DateTime(2026, 11, 12)));
    expect(vm.ultimoDia, DateTime(2026, 11, 11));
  });

  test('ordena de mayor a menor y deja los incompletos al final', () async {
    responder({coco: d('1000'), platano: null, aceite: d('2500')});
    final vm = crear();

    await vm.cargar();

    expect(vm.filas.map((f) => f.producto.getNombre()), [
      'Aceite 1 L',
      'Coco',
      'Plátano',
    ]);
    expect(vm.gananciaTotal, d('3500'));
    expect(vm.productosConVentas, 3);
    expect(vm.productosSinCosto, 1);
    expect(vm.mayorGanancia, d('2500'));
  });

  test('periodo sin ventas: sin filas ni error', () async {
    responder({});
    final vm = crear();

    await vm.cargar();

    expect(vm.filas, isEmpty);
    expect(vm.error, isNull);
    expect(vm.gananciaTotal, Decimal.zero);
  });

  test('el empleado ve el mensaje de solo propietario', () async {
    when(() => coordinador.consultarMargen(any(), any(), any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());
    final vm = crear(propietaria: false);

    await vm.cargar();

    expect(vm.error, 'Esta consulta es solo para el propietario');
    expect(vm.filas, isEmpty);
    expect(vm.cargando, isFalse);
  });

  test('una falla inesperada da un mensaje para el tendero', () async {
    when(() => coordinador.consultarMargen(any(), any(), any(), any()))
        .thenThrow(StateError('x'));
    final vm = crear();

    await vm.cargar();

    expect(vm.error, 'No se pudo calcular la ganancia. Intente de nuevo');
  });
}
