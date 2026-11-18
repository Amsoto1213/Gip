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

  group('buscarPorLectura (CUS-17)', () {
    void sinNombres() =>
        when(() => coordinator.buscarPorNombre(any(), any()))
            .thenAnswer((_) async => []);

    test('devuelve el producto del código y lo deja como resultado', () async {
      when(() => coordinator.buscarPorLectura(tienda, '7701234567897'))
          .thenAnswer((_) async => coco);

      final hallado = await vm.buscarPorLectura(' 7701234567897 ');

      expect(hallado, coco);
      expect(vm.productos, [coco]);
      expect(vm.estado, EstadoBusqueda.conResultados);
      expect(vm.codigoNoRegistrado, isNull);
    });

    test('con resultados por nombre los deja si el código no existe', () async {
      when(() => coordinator.buscarPorNombre(tienda, 'co'))
          .thenAnswer((_) async => [coco, cafe]);
      when(() => coordinator.buscarPorLectura(tienda, 'co'))
          .thenAnswer((_) async => null);
      await vm.buscar('co');

      expect(await vm.buscarPorLectura('co'), isNull);

      expect(vm.productos, [coco, cafe]);
      expect(vm.estado, EstadoBusqueda.conResultados);
      expect(vm.codigoNoRegistrado, isNull);
    });

    test('un código no registrado ofrece crearlo con ese código', () async {
      sinNombres();
      when(() => coordinator.buscarPorLectura(any(), any()))
          .thenAnswer((_) async => null);
      await vm.buscar('7701234567897');

      expect(await vm.buscarPorLectura('7701234567897'), isNull);

      expect(vm.estado, EstadoBusqueda.sinCoincidencias);
      expect(vm.codigoNoRegistrado, '7701234567897');
    });

    test('escribir de nuevo quita el código no registrado', () async {
      sinNombres();
      when(() => coordinator.buscarPorLectura(any(), any()))
          .thenAnswer((_) async => null);
      await vm.buscarPorLectura('7701234567897');

      await vm.buscar('leche');

      expect(vm.codigoNoRegistrado, isNull);
    });

    test('desde la cámara reemplaza el texto y los resultados', () async {
      when(() => coordinator.buscarPorNombre(tienda, 'ca'))
          .thenAnswer((_) async => [cafe]);
      when(() => coordinator.buscarPorLectura(tienda, 'GIP:P1'))
          .thenAnswer((_) async => coco);
      await vm.buscar('ca');

      final hallado = await vm.buscarPorLectura('GIP:P1', desdeCamara: true);

      expect(hallado, coco);
      expect(vm.texto, 'GIP:P1');
      expect(vm.productos, [coco]);
    });

    test(
      'desde la cámara, un código no registrado limpia los resultados',
      () async {
        when(() => coordinator.buscarPorNombre(tienda, 'ca'))
            .thenAnswer((_) async => [cafe]);
        when(() => coordinator.buscarPorLectura(any(), any()))
            .thenAnswer((_) async => null);
        await vm.buscar('ca');

        await vm.buscarPorLectura('7701234567897', desdeCamara: true);

        expect(vm.productos, isEmpty);
        expect(vm.estado, EstadoBusqueda.sinCoincidencias);
        expect(vm.codigoNoRegistrado, '7701234567897');
      },
    );

    test('después de una lectura, repetirBusqueda vuelve a leer', () async {
      when(() => coordinator.buscarPorLectura(tienda, '7701234567897'))
          .thenAnswer((_) async => coco);
      await vm.buscarPorLectura('7701234567897', desdeCamara: true);

      await vm.repetirBusqueda();

      verify(() => coordinator.buscarPorLectura(tienda, '7701234567897'))
          .called(2);
      verifyNever(() => coordinator.buscarPorNombre(any(), any()));
      expect(vm.productos, [coco]);
    });

    test('una lectura vacía no busca', () async {
      expect(await vm.buscarPorLectura('   '), isNull);
      verifyNever(() => coordinator.buscarPorLectura(any(), any()));
    });

    test(
      'si se sigue escribiendo, no marca el código como no registrado',
      () async {
        sinNombres();
        final lectura = Completer<Producto?>();
        when(() => coordinator.buscarPorLectura(any(), any()))
            .thenAnswer((_) => lectura.future);

        final pendiente = vm.buscarPorLectura('770');
        await vm.buscar('leche');
        lectura.complete(null);
        await pendiente;

        expect(vm.codigoNoRegistrado, isNull);
        expect(vm.texto, 'leche');
      },
    );

    test('si falla muestra el mensaje para el tendero', () async {
      when(() => coordinator.buscarPorLectura(any(), any()))
          .thenThrow(StateError('disco'));

      expect(await vm.buscarPorLectura('7701234567897'), isNull);

      expect(vm.error, 'No se pudo buscar el producto. Inténtalo de nuevo');
    });

    test('lectura fallida de la cámara deja el aviso hasta buscar', () async {
      sinNombres();
      vm.lecturaFallida();

      expect(
        vm.avisoLectura,
        'No se pudo usar la cámara. Busque el producto por nombre',
      );

      await vm.buscar('leche');
      expect(vm.avisoLectura, isNull);
    });
  });
}
