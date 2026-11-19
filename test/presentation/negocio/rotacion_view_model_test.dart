import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/presentation/negocio/rotacion_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_alertas.dart';
import 'rotacion_falsos.dart';

void main() {
  late ConsultarRotacionFalso coordinador;
  // Domingo 15 de noviembre de 2026.
  final ahora = DateTime(2026, 11, 15, 9, 30);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = ConsultarRotacionFalso());

  RotacionViewModel crear({bool propietaria = true}) => RotacionViewModel(
    coordinador,
    propietaria ? propietariaAlertas : empleadoAlertas,
    reloj: () => ahora,
  );

  void responder(Map<Producto, Rotacion> rotacion) =>
      when(() => coordinador.consultarRotacion(any(), any(), any(), any()))
          .thenAnswer((_) async => rotacion);

  (DateTime, DateTime) ultimoPeriodo() {
    final args = verify(
      () => coordinador.consultarRotacion(
        any(),
        captureAny(),
        captureAny(),
        any(),
      ),
    ).captured;
    return (args[0] as DateTime, args[1] as DateTime);
  }

  test('empieza en 30 días: hoy y los 29 anteriores', () async {
    responder({});
    final vm = crear();

    await vm.cargar();

    expect(vm.periodo, PeriodoRotacion.dias30);
    expect(ultimoPeriodo(), (DateTime(2026, 10, 17), DateTime(2026, 11, 16)));
    expect(vm.desde, DateTime(2026, 10, 17));
    expect(vm.ultimoDia, DateTime(2026, 11, 15));
  });

  test('este mes va del día 1 a hoy', () async {
    responder({});
    final vm = crear();

    await vm.elegirPeriodo(PeriodoRotacion.mes);

    expect(ultimoPeriodo(), (DateTime(2026, 11, 1), DateTime(2026, 11, 16)));
  });

  test('un rango de fechas incluye el último día', () async {
    responder({});
    final vm = crear();

    await vm.elegirFechas(DateTime(2026, 11, 5), DateTime(2026, 11, 11));

    expect(vm.periodo, PeriodoRotacion.fechas);
    expect(ultimoPeriodo(), (DateTime(2026, 11, 5), DateTime(2026, 11, 12)));
    expect(vm.ultimoDia, DateTime(2026, 11, 11));
  });

  test('elegir Fechas sin haber elegido un rango no consulta', () async {
    responder({});
    final vm = crear();

    await vm.elegirPeriodo(PeriodoRotacion.fechas);

    expect(vm.periodo, PeriodoRotacion.dias30);
    verifyNever(
      () => coordinador.consultarRotacion(any(), any(), any(), any()),
    );
  });

  test(
    'reparte los productos por grupo y conserva el orden recibido',
    () async {
      responder({
        coco: Rotacion.alta,
        aceite: Rotacion.alta,
        platano: Rotacion.baja,
      });
      final vm = crear();

      await vm.cargar();

      expect(vm.productosDe(Rotacion.alta).map((p) => p.getNombre()), [
        'Coco',
        'Aceite 1 L',
      ]);
      expect(vm.productosDe(Rotacion.media), isEmpty);
      expect(vm.productosDe(Rotacion.baja).single.getNombre(), 'Plátano');
      expect(vm.cantidadDe(Rotacion.alta), 2);
      expect(vm.cantidadDe(Rotacion.media), 0);
      expect(vm.cantidadDe(Rotacion.baja), 1);
      expect(vm.totalProductos, 3);
      expect(vm.error, isNull);
    },
  );

  test('elegir grupo cambia lo que se ve sin consultar de nuevo', () async {
    responder({coco: Rotacion.alta});
    final vm = crear();
    await vm.cargar();
    var avisos = 0;
    vm.addListener(() => avisos++);

    vm.elegirGrupo(Rotacion.baja);

    expect(vm.grupo, Rotacion.baja);
    expect(avisos, 1);
    verify(() => coordinador.consultarRotacion(any(), any(), any(), any()))
        .called(1);
  });

  test('sin productos: grupos vacíos y sin error', () async {
    responder({});
    final vm = crear();

    await vm.cargar();

    expect(vm.totalProductos, 0);
    expect(vm.error, isNull);
  });

  test('el empleado ve el mensaje de solo propietario', () async {
    when(() => coordinador.consultarRotacion(any(), any(), any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());
    final vm = crear(propietaria: false);

    await vm.cargar();

    expect(vm.error, 'Esta consulta es solo para el propietario');
    expect(vm.totalProductos, 0);
    expect(vm.cargando, isFalse);
  });

  test('una falla inesperada da un mensaje para el tendero', () async {
    when(() => coordinador.consultarRotacion(any(), any(), any(), any()))
        .thenThrow(StateError('x'));
    final vm = crear();

    await vm.cargar();

    expect(vm.error, 'No se pudo calcular la rotación. Intente de nuevo');
    expect(vm.cargando, isFalse);
  });

  test('tras un error, una consulta buena lo limpia', () async {
    when(() => coordinador.consultarRotacion(any(), any(), any(), any()))
        .thenThrow(StateError('x'));
    final vm = crear();
    await vm.cargar();

    responder({coco: Rotacion.alta});
    await vm.cargar();

    expect(vm.error, isNull);
    expect(vm.cantidadDe(Rotacion.alta), 1);
  });
}
