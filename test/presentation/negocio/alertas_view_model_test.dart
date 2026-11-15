import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/negocio/alertas_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import 'alertas_falsos.dart';
import 'datos_alertas.dart';

void main() {
  late ConsultarAlertasFalso coordinador;
  final ahora = DateTime(2026, 11, 15, 9, 30);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = ConsultarAlertasFalso());

  AlertasViewModel crear([UsuarioActivo? usuario]) => AlertasViewModel(
    coordinador,
    usuario ?? propietariaAlertas,
    reloj: () => ahora,
  );

  void responder() {
    when(() => coordinador.consultarAlertas(any(), any(), any()))
        .thenAnswer((_) async => alertasDelMockup);
    when(() => coordinador.consultarVentasPerdidas(any(), any(), any(), any()))
        .thenAnswer((_) async => ventasPerdidasDelMockup);
  }

  test('carga las alertas de hoy y las ventas perdidas de 30 días', () async {
    responder();
    final vm = crear();

    await vm.cargar();

    expect(vm.error, isNull);
    expect(vm.cargando, isFalse);
    expect(vm.alertas, hasLength(3));
    expect(vm.ventasPerdidas, hasLength(3));
    expect(vm.hayProvisionales, isTrue);
    verify(
      () => coordinador.consultarAlertas(
        tiendaAlertas,
        DateTime(2026, 11, 15),
        propietariaAlertas.usuario,
      ),
    ).called(1);
    verify(
      () => coordinador.consultarVentasPerdidas(
        tiendaAlertas,
        DateTime(2026, 10, 16),
        DateTime(2026, 11, 16),
        propietariaAlertas.usuario,
      ),
    ).called(1);
  });

  test('cuenta las veces que se fue sin comprar cada producto', () async {
    responder();
    final vm = crear();
    await vm.cargar();

    expect(vm.ventasPerdidasDe(coco), 3);
    expect(vm.ventasPerdidasDe(platano), 0);
  });

  test('al empleado le muestra el mensaje del diagrama', () async {
    when(() => coordinador.consultarAlertas(any(), any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());
    final vm = crear(empleadoAlertas);

    await vm.cargar();

    expect(vm.error, 'Esta consulta es solo para el propietario');
    expect(vm.alertas, isEmpty);
    verifyNever(
      () => coordinador.consultarVentasPerdidas(any(), any(), any(), any()),
    );
  });

  test('una falla inesperada da un mensaje para el tendero', () async {
    when(() => coordinador.consultarAlertas(any(), any(), any()))
        .thenThrow(StateError('disco'));
    final vm = crear();

    await vm.cargar();

    expect(vm.error, 'No se pudieron cargar las alertas. Intente de nuevo');
  });

  test('cambia de pestaña y avisa', () async {
    final vm = crear();
    var avisos = 0;
    vm.addListener(() => avisos++);

    vm.elegirPestana(PestanaAlertas.ventasPerdidas);
    vm.elegirPestana(PestanaAlertas.ventasPerdidas);

    expect(vm.pestana, PestanaAlertas.ventasPerdidas);
    expect(avisos, 1);
  });

  test(
    'sin alertas queda vacía para mostrar el mensaje del diagrama',
    () async {
      when(() => coordinador.consultarAlertas(any(), any(), any()))
          .thenAnswer((_) async => []);
      when(
        () => coordinador.consultarVentasPerdidas(any(), any(), any(), any()),
      ).thenAnswer((_) async => []);
      final vm = crear();

      await vm.cargar();

      expect(vm.alertas, isEmpty);
      expect(
        AlertasViewModel.mensajeSinAlertas,
        'No hay productos por agotarse',
      );
    },
  );
}
