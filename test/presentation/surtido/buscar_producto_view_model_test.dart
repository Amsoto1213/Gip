import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:mocktail/mocktail.dart';

class BuscarProductoFalso extends Mock implements BuscarProductoCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Producto producto(String id, String nombre) => Producto(
    id,
    id.toUpperCase(),
    nombre,
    UnidadMedida.unidad,
    null,
    Decimal.parse('3000'),
  );
  final coco = producto('p1', 'Coco');
  final cafe = producto('p2', 'Café molido 250 g');

  late BuscarProductoFalso coordinator;
  late BuscarProductoViewModel vm;

  setUpAll(() => registerFallbackValue(tienda));
  setUp(() {
    coordinator = BuscarProductoFalso();
    vm = BuscarProductoViewModel(coordinator, tienda);
  });

  test('empieza sin buscar', () {
    expect(vm.estado, EstadoBusqueda.inicial);
    expect(vm.productos, isEmpty);
  });

  test(
    'busca en la tienda con el texto escrito y muestra los productos',
    () async {
      when(() => coordinator.buscarPorNombre(tienda, 'co'))
          .thenAnswer((_) async => [coco, cafe]);

      await vm.buscar('co');

      expect(vm.estado, EstadoBusqueda.conResultados);
      expect(vm.productos, [coco, cafe]);
      verify(() => coordinator.buscarPorNombre(tienda, 'co')).called(1);
    },
  );

  test('sin coincidencias queda en sinCoincidencias', () async {
    when(() => coordinator.buscarPorNombre(any(), any()))
        .thenAnswer((_) async => []);

    await vm.buscar('leche');

    expect(vm.estado, EstadoBusqueda.sinCoincidencias);
    expect(
      BuscarProductoViewModel.mensajeSinCoincidencias,
      'No se encontró el producto. ¿Desea crearlo?',
    );
  });

  test('con el texto vacío no busca y vuelve al inicio', () async {
    when(() => coordinator.buscarPorNombre(any(), any()))
        .thenAnswer((_) async => [coco]);
    await vm.buscar('co');

    await vm.buscar('   ');

    expect(vm.estado, EstadoBusqueda.inicial);
    expect(vm.productos, isEmpty);
    verify(() => coordinator.buscarPorNombre(any(), any())).called(1);
  });

  test('descarta la respuesta de una consulta vieja', () async {
    final vieja = Completer<List<Producto>>();
    when(() => coordinator.buscarPorNombre(tienda, 'c'))
        .thenAnswer((_) => vieja.future);
    when(() => coordinator.buscarPorNombre(tienda, 'coc'))
        .thenAnswer((_) async => [coco]);

    final primera = vm.buscar('c');
    await vm.buscar('coc');
    vieja.complete([coco, cafe]);
    await primera;

    expect(vm.texto, 'coc');
    expect(vm.productos, [coco]);
  });

  test('repetirBusqueda vuelve a buscar el mismo texto', () async {
    when(() => coordinator.buscarPorNombre(tienda, 'co'))
        .thenAnswer((_) async => [coco]);
    await vm.buscar('co');

    await vm.repetirBusqueda();

    verify(() => coordinator.buscarPorNombre(tienda, 'co')).called(2);
  });

  test('si la búsqueda falla muestra un mensaje para el tendero', () async {
    when(() => coordinator.buscarPorNombre(any(), any()))
        .thenThrow(StateError('disco'));

    await vm.buscar('co');

    expect(vm.error, 'No se pudo buscar el producto. Inténtalo de nuevo');
    expect(vm.productos, isEmpty);
  });
}
