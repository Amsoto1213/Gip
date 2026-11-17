import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/surtido/existencias_view_model.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';

import 'datos_existencias.dart';
import 'existencias_falsos.dart';

void main() {
  late ConsultarExistenciasFalso coordinador;
  late ExistenciasViewModel vm;

  setUp(() {
    coordinador = coordinadorExistencias();
    vm = ExistenciasViewModel(
      coordinador,
      tiendaExistencias,
      reloj: ahoraExistencias,
    );
  });

  List<String> nombres() =>
      vm.visibles.map((i) => i.getProducto().getNombre()).toList();

  group('cargar', () {
    test('lista los productos en el orden del coordinador', () async {
      expect(vm.cargado, isFalse);

      await vm.cargar();

      expect(vm.cargado, isTrue);
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(nombres(), ['Aceite 1 L', 'Arroz 500 g', 'Queso costeño']);
      expect(vm.total, 3);
      expect(vm.agotados, 1);
    });

    test('mientras carga avisa con cargando', () async {
      coordinador.esperaListar = Completer<void>();
      final carga = vm.cargar();
      expect(vm.cargando, isTrue);

      coordinador.esperaListar!.complete();
      await carga;
      expect(vm.cargando, isFalse);
    });

    test('un error de negocio muestra su mensaje', () async {
      coordinador.fallaListar = const ExcepcionProductoSinInventario();

      await vm.cargar();

      expect(vm.error, const ExcepcionProductoSinInventario().mensaje);
      expect(vm.cargado, isFalse);
    });

    test('otra falla muestra el mensaje genérico', () async {
      coordinador.fallaListar = StateError('disco');

      await vm.cargar();

      expect(vm.error, ExistenciasViewModel.mensajeFalla);
    });

    test('al recargar sin error se ve la lista nueva', () async {
      await vm.cargar();
      coordinador.items = [itemArroz];

      await vm.cargar();

      expect(nombres(), ['Arroz 500 g']);
      expect(vm.total, 1);
    });
  });

  group('filtros', () {
    setUp(() => vm.cargar());

    test('Agotados: existencia en cero o menos', () {
      vm.elegirFiltro(FiltroExistencias.agotados);
      expect(nombres(), ['Queso costeño']);
    });

    test('Por peso: kilo y libra', () {
      vm.elegirFiltro(FiltroExistencias.porPeso);
      expect(nombres(), ['Queso costeño']);
    });

    test('Todos vuelve a mostrar todo', () {
      vm
        ..elegirFiltro(FiltroExistencias.agotados)
        ..elegirFiltro(FiltroExistencias.todos);
      expect(nombres(), hasLength(3));
    });

    test('el filtro no cambia los totales', () {
      vm.elegirFiltro(FiltroExistencias.agotados);
      expect(vm.total, 3);
      expect(vm.agotados, 1);
    });
  });

  group('alternarDetalle (últimos movimientos)', () {
    setUp(() => vm.cargar());

    test(
      'consulta los últimos 30 días contando hoy, en días locales',
      () async {
        await vm.alternarDetalle(aceite);

        final consulta = coordinador.consultas.single;
        expect(consulta.producto, aceite);
        expect(consulta.desde, DateTime(2026, 10, 19));
        expect(consulta.hasta, DateTime(2026, 11, 18));
      },
    );

    test('trae los del periodo del más reciente al más antiguo', () async {
      await vm.alternarDetalle(aceite);

      expect(vm.abierto, aceite.getId());
      expect(vm.historial!.cargando, isFalse);
      expect(vm.historial!.movimientos.map((m) => m.getId()), [
        'e-hoy',
        's-hoy',
        'a-ayer',
        'm-anulada',
      ]);
    });

    test('tocar otra vez el mismo producto lo cierra', () async {
      await vm.alternarDetalle(aceite);
      await vm.alternarDetalle(aceite);

      expect(vm.abierto, isNull);
      expect(vm.historial, isNull);
    });

    test('abrir otro producto cierra el anterior', () async {
      await vm.alternarDetalle(aceite);
      await vm.alternarDetalle(arroz);

      expect(vm.abierto, arroz.getId());
      expect(vm.historial!.movimientos, isEmpty);
    });

    test('si falla muestra el mensaje del historial', () async {
      coordinador.fallaMovimientos = StateError('disco');

      await vm.alternarDetalle(aceite);

      expect(vm.historial!.error, ExistenciasViewModel.mensajeFallaHistorial);
    });

    test('al recargar la lista se vuelve a consultar el abierto', () async {
      await vm.alternarDetalle(aceite);
      await vm.cargar();
      await pumpEventQueue();

      expect(coordinador.consultas, hasLength(2));
      expect(vm.abierto, aceite.getId());
    });

    test('si el producto abierto ya no está, el panel se cierra', () async {
      await vm.alternarDetalle(aceite);
      coordinador.items = [itemArroz];

      await vm.cargar();

      expect(vm.abierto, isNull);
    });
  });

  group('pedirUltimoMovimiento (columna web)', () {
    setUp(() => vm.cargar());

    test(
      'consulta todo el historial hasta mañana y toma el más reciente',
      () async {
        await vm.pedirUltimoMovimiento(aceite);

        final consulta = coordinador.consultas.single;
        expect(consulta.desde, ExistenciasViewModel.inicioHistorial);
        expect(consulta.hasta, DateTime(2026, 11, 18));
        expect(vm.ultimoMovimientoListo(aceite), isTrue);
        expect(vm.ultimoMovimiento(aceite)!.getId(), 'e-hoy');
      },
    );

    test('mientras no llega no está listo', () {
      final pedido = vm.pedirUltimoMovimiento(aceite);

      expect(vm.ultimoMovimientoListo(aceite), isFalse);
      expect(vm.ultimoMovimiento(aceite), isNull);
      return pedido;
    });

    test('pedirlo dos veces consulta una sola vez', () async {
      await Future.wait([
        vm.pedirUltimoMovimiento(aceite),
        vm.pedirUltimoMovimiento(aceite),
      ]);
      await vm.pedirUltimoMovimiento(aceite);

      expect(coordinador.consultas, hasLength(1));
    });

    test('sin movimientos queda listo y vacío', () async {
      await vm.pedirUltimoMovimiento(arroz);

      expect(vm.ultimoMovimientoListo(arroz), isTrue);
      expect(vm.ultimoMovimiento(arroz), isNull);
    });

    test('si falla la columna queda vacía', () async {
      coordinador.fallaMovimientos = StateError('disco');

      await vm.pedirUltimoMovimiento(aceite);

      expect(vm.ultimoMovimientoListo(aceite), isTrue);
      expect(vm.ultimoMovimiento(aceite), isNull);
    });

    test('al recargar la lista se vuelven a pedir', () async {
      await vm.pedirUltimoMovimiento(aceite);

      await vm.cargar();
      await pumpEventQueue();

      expect(coordinador.consultas, hasLength(2));
      expect(vm.ultimoMovimiento(aceite)!.getId(), 'e-hoy');
    });
  });
}
