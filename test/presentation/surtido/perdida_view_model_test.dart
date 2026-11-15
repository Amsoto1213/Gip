import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

class CoordinadorFalso extends Mock implements RegistrarPerdidaCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final leche = Producto(
    'p1',
    'LEC-1',
    'Leche bolsa 1 L',
    UnidadMedida.unidad,
    null,
    Decimal.parse('4200'),
  );
  final queso = Producto(
    'p2',
    'QUE-1',
    'Queso costeño',
    UnidadMedida.kilogramo,
    null,
    Decimal.parse('24000'),
  );
  Decimal d(String v) => Decimal.parse(v);

  late CoordinadorFalso coordinador;
  late PerdidaViewModel vm;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(leche);
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(MotivoMerma.otro);
  });

  setUp(() {
    coordinador = CoordinadorFalso();
    vm = PerdidaViewModel(coordinador, tienda);
    when(() => coordinador.consultarExistencia(any(), any()))
        .thenAnswer((_) async => d('14'));
  });
  tearDown(() => vm.dispose());

  Merma mermaCon(Producto p, String stock, String cantidad) => Merma(
    'm1',
    ItemInventario('i1', p, d(stock)),
    -d(cantidad),
    DateTime.utc(2026, 11, 14),
    MotivoMerma.vencido,
  );

  test(
    'al elegir el producto consulta la existencia y calcula Quedará en',
    () async {
      await vm.elegirProducto(leche);
      expect(vm.existencia, d('14'));
      vm.cambiarCantidad('2');
      expect(vm.quedaraEn, d('12'));
      verify(() => coordinador.consultarExistencia(tienda, leche)).called(1);
    },
  );

  test('Quedará en es null si la cantidad supera la existencia', () async {
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('15');
    expect(vm.cantidad, d('15'));
    expect(vm.quedaraEn, isNull);
  });

  test('no deja confirmar sin motivo ni sin producto (IE-03)', () async {
    expect(vm.puedeConfirmar, isFalse);
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('2');
    expect(vm.puedeConfirmar, isFalse);
    expect(await vm.registrar(), isFalse);
    verifyNever(() => coordinador.registrarPerdida(any(), any(), any(), any()));

    vm.elegirMotivo(MotivoMerma.danado);
    expect(vm.puedeConfirmar, isTrue);
  });

  group('cantidad según la unidad', () {
    test('kilos y libras aceptan decimales con coma', () async {
      await vm.elegirProducto(queso);
      expect(vm.admiteDecimales, isTrue);
      vm.cambiarCantidad('2,5');
      expect(vm.cantidad, d('2.5'));
      expect(vm.error, isNull);
    });

    test('un producto por unidad no acepta decimales', () async {
      await vm.elegirProducto(leche);
      expect(vm.admiteDecimales, isFalse);
      vm.cambiarCantidad('2,5');
      expect(vm.cantidad, isNull);
      expect(vm.error, PerdidaViewModel.mensajeSoloEnteros);
    });

    test('los botones − y + suman de a uno y no bajan de cero', () {
      expect(vm.sumarCantidad(Decimal.one), Decimal.one);
      expect(vm.sumarCantidad(Decimal.one), d('2'));
      vm.sumarCantidad(-Decimal.one);
      vm.sumarCantidad(-Decimal.one);
      expect(vm.sumarCantidad(-Decimal.one), Decimal.zero);
    });
  });

  test('sin cantidad pide escribirla y no llama al coordinador', () async {
    await vm.elegirProducto(leche);
    vm.elegirMotivo(MotivoMerma.otro);
    expect(await vm.registrar(), isFalse);
    expect(vm.error, PerdidaViewModel.mensajeSinCantidad);
    verifyNever(() => coordinador.registrarPerdida(any(), any(), any(), any()));
  });

  test('registra con el motivo y muestra el nuevo stock', () async {
    when(
      () => coordinador.registrarPerdida(
        tienda,
        leche,
        d('2'),
        MotivoMerma.vencido,
      ),
    ).thenAnswer((_) async => mermaCon(leche, '12', '2'));
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('2');
    vm.elegirMotivo(MotivoMerma.vencido);

    expect(await vm.registrar(), isTrue);

    expect(vm.aviso, 'Pérdida registrada. Nuevo stock: 12');
    expect(vm.existencia, d('12'));
    expect(vm.cantidad, isNull);
    expect(vm.motivo, isNull);
    expect(vm.error, isNull);
    verify(
      () => coordinador.registrarPerdida(
        tienda,
        leche,
        d('2'),
        MotivoMerma.vencido,
      ),
    ).called(1);
  });

  test('cantidad mayor a la existencia: muestra el mensaje y vuelve a leer la '
      'existencia', () async {
    when(
      () => coordinador.registrarPerdida(any(), any(), any(), any()),
    ).thenAnswer((_) async => throw const ExcepcionCantidadSuperaExistencia());
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('20');
    vm.elegirMotivo(MotivoMerma.danado);

    expect(await vm.registrar(), isFalse);
    await pumpEventQueue();

    expect(vm.error, 'La cantidad supera la existencia');
    expect(vm.aviso, isNull);
    expect(vm.cantidad, d('20'));
    verify(() => coordinador.consultarExistencia(tienda, leche)).called(2);
  });

  test('muestra el mensaje de datos no válidos del servicio', () async {
    when(() => coordinador.registrarPerdida(any(), any(), any(), any()))
        .thenAnswer((_) async => throw const ExcepcionDatosMermaNoValidos());
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('0');
    vm.elegirMotivo(MotivoMerma.otro);

    expect(await vm.registrar(), isFalse);
    expect(
      vm.error,
      'La cantidad debe ser mayor que cero y el motivo es obligatorio',
    );
  });

  test('un error inesperado muestra el mensaje del diagrama', () async {
    when(() => coordinador.registrarPerdida(any(), any(), any(), any()))
        .thenAnswer((_) async => throw StateError('disco'));
    await vm.elegirProducto(leche);
    vm.cambiarCantidad('1');
    vm.elegirMotivo(MotivoMerma.otro);

    expect(await vm.registrar(), isFalse);
    expect(vm.error, PerdidaViewModel.mensajeErrorGuardar);
  });

  test('descarta la existencia de un producto que ya se cambió', () async {
    final lenta = Completer<Decimal>();
    when(() => coordinador.consultarExistencia(tienda, leche))
        .thenAnswer((_) => lenta.future);
    when(() => coordinador.consultarExistencia(tienda, queso))
        .thenAnswer((_) async => d('3.5'));

    final primera = vm.elegirProducto(leche);
    await vm.elegirProducto(queso);
    lenta.complete(d('14'));
    await primera;

    expect(vm.producto, queso);
    expect(vm.existencia, d('3.5'));
  });

  test('producto sin inventario muestra el mensaje del servicio', () async {
    when(() => coordinador.consultarExistencia(any(), any()))
        .thenAnswer((_) async => throw const ExcepcionProductoSinInventario());
    await vm.elegirProducto(leche);
    expect(vm.existencia, isNull);
    expect(vm.error, 'El producto no tiene inventario en esta tienda');
  });
}
