import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/presentation/surtido/conteo_view_model.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

class CoordinadorFalso extends Mock implements RegistrarConteoCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  Producto producto(String id, String nombre, [UnidadMedida? unidad]) =>
      Producto(
        id,
        id.toUpperCase(),
        nombre,
        unidad ?? UnidadMedida.unidad,
        null,
        d('1000'),
      );

  final arroz = producto('p1', 'Arroz 500 g');
  final cafe = producto('p2', 'Café molido 250 g');
  final huevo = producto('p3', 'Huevo AA');
  final queso = producto('p4', 'Queso costeño', UnidadMedida.kilogramo);
  final stock = {'p1': '46', 'p2': '21', 'p3': '90', 'p4': '3'};

  late CoordinadorFalso coordinador;
  late ConteoViewModel vm;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(arroz);
    registerFallbackValue(Decimal.zero);
  });

  setUp(() async {
    coordinador = CoordinadorFalso();
    when(() => coordinador.listarExistencias(tienda)).thenAnswer(
      (_) async => [
        for (final p in [arroz, cafe, huevo, queso])
          ItemInventario('i-${p.getId()}', p, d(stock[p.getId()]!)),
      ],
    );
    when(() => coordinador.calcularDiferencia(tienda, any(), any()))
        .thenAnswer((inv) async {
          final p = inv.positionalArguments[1] as Producto;
          final contada = inv.positionalArguments[2] as Decimal;
          return contada - d(stock[p.getId()]!);
        });
    when(() => coordinador.requiereRevision(any())).thenAnswer(
      (inv) => (inv.positionalArguments.first as Decimal).abs() > d('5'),
    );
    vm = ConteoViewModel(coordinador, tienda);
    await vm.cargar();
  });
  tearDown(() => vm.dispose());

  FilaConteo fila(Producto p) =>
      vm.todas.firstWhere((f) => f.producto.getId() == p.getId());

  void ajusteResponde() =>
      when(() => coordinador.confirmarAjuste(tienda, any(), any()))
          .thenAnswer((inv) async {
            final p = inv.positionalArguments[1] as Producto;
            final contada = inv.positionalArguments[2] as Decimal;
            return AjusteConteo(
              'a-${p.getId()}',
              ItemInventario('i-${p.getId()}', p, contada),
              contada - d(stock[p.getId()]!),
              DateTime.utc(2026, 11, 14),
              contada,
            );
          });

  test('carga los productos con su existencia, ninguno contado', () {
    expect(vm.total, 4);
    expect(vm.contados, 0);
    expect(fila(huevo).item.getStockActual(), d('90'));
    expect(vm.puedeConfirmar, isFalse);
  });

  test('si no se puede cargar muestra el mensaje', () async {
    when(() => coordinador.listarExistencias(tienda))
        .thenAnswer((_) async => throw StateError('disco'));
    final otro = ConteoViewModel(coordinador, tienda);
    await otro.cargar();
    expect(otro.error, ConteoViewModel.mensajeErrorCargar);
    otro.dispose();
  });

  group('diferencia al escribir', () {
    test('positiva', () async {
      await vm.cambiarCantidad(cafe, '23');
      expect(fila(cafe).diferencia, d('2'));
      expect(fila(cafe).revisar, isFalse);
    });

    test('negativa y por encima del umbral pide revisar', () async {
      await vm.cambiarCantidad(huevo, '78');
      expect(fila(huevo).diferencia, d('-12'));
      expect(fila(huevo).revisar, isTrue);
      expect(vm.porRevisar, 1);
    });

    test('cero: cuadra', () async {
      await vm.cambiarCantidad(arroz, '46');
      expect(fila(arroz).diferencia, d('0'));
      expect(vm.conDiferencia, 0);
    });

    test('justo en el umbral no pide revisar; por encima sí', () async {
      await vm.cambiarCantidad(arroz, '51');
      expect(fila(arroz).revisar, isFalse);
      await vm.cambiarCantidad(arroz, '52');
      expect(fila(arroz).revisar, isTrue);
    });

    test('el aviso no bloquea la confirmación', () async {
      await vm.cambiarCantidad(huevo, '78');
      expect(vm.puedeConfirmar, isTrue);
    });

    test('kilos y libras aceptan decimales con coma', () async {
      await vm.cambiarCantidad(queso, '2,5');
      expect(fila(queso).contada, d('2.5'));
      expect(fila(queso).diferencia, d('-0.5'));
    });

    test('por unidad no acepta decimales y no deja confirmar', () async {
      await vm.cambiarCantidad(cafe, '2,5');
      expect(fila(cafe).contada, isNull);
      expect(fila(cafe).error, ConteoViewModel.mensajeSoloEnteros);
      expect(vm.puedeConfirmar, isFalse);
      verifyNever(() => coordinador.calcularDiferencia(any(), any(), any()));
    });

    test('descarta la respuesta de una consulta vieja', () async {
      final lenta = Completer<Decimal>();
      when(() => coordinador.calcularDiferencia(tienda, cafe, d('1')))
          .thenAnswer((_) => lenta.future);
      final primera = vm.cambiarCantidad(cafe, '1');
      await vm.cambiarCantidad(cafe, '23');
      lenta.complete(d('-20'));
      await primera;
      expect(fila(cafe).diferencia, d('2'));
    });

    test('volver a contar borra la cantidad', () async {
      await vm.cambiarCantidad(huevo, '78');
      vm.volverAContar(huevo);
      expect(fila(huevo).contado, isFalse);
      expect(fila(huevo).revisar, isFalse);
      expect(fila(huevo).texto, '');
    });
  });

  group('filtros', () {
    test('por nombre sin tildes ni mayúsculas (como CUS-06)', () {
      vm.buscar('CAFE');
      expect(vm.filas.map((f) => f.producto.getNombre()), [
        'Café molido 250 g',
      ]);
      vm.buscar('  queso   COSTEÑO ');
      expect(vm.filas.single.producto, same(queso));
    });

    test('contados, sin contar y con diferencia', () async {
      await vm.cambiarCantidad(arroz, '46');
      await vm.cambiarCantidad(huevo, '78');
      vm.elegirFiltro(FiltroConteo.contados);
      expect(vm.filas.length, 2);
      vm.elegirFiltro(FiltroConteo.sinContar);
      expect(vm.filas.length, 2);
      vm.elegirFiltro(FiltroConteo.conDiferencia);
      expect(vm.filas.single.producto, same(huevo));
    });

    test('la fila que se escribe no se va hasta cambiar el filtro', () async {
      vm.elegirFiltro(FiltroConteo.sinContar);
      await vm.cambiarCantidad(cafe, '23');
      expect(vm.filas.map((f) => f.producto), contains(same(cafe)));
      expect(vm.sinContar, 3);
      vm.elegirFiltro(FiltroConteo.sinContar);
      expect(vm.filas.map((f) => f.producto), isNot(contains(same(cafe))));
    });
  });

  group('confirmar', () {
    test('un producto: "Ajuste registrado. Nuevo stock: N"', () async {
      ajusteResponde();
      await vm.cambiarCantidad(huevo, '78');
      await vm.confirmar();

      verify(() => coordinador.confirmarAjuste(tienda, huevo, d('78')))
          .called(1);
      expect(vm.aviso, 'Ajuste registrado. Nuevo stock: 78');
      expect(fila(huevo).item.getStockActual(), d('78'));
      expect(fila(huevo).contado, isFalse);
      expect(vm.contados, 0);
    });

    test('varios productos, incluido uno que cuadra, uno por uno', () async {
      ajusteResponde();
      await vm.cambiarCantidad(arroz, '46');
      await vm.cambiarCantidad(cafe, '23');
      await vm.confirmar();

      verify(() => coordinador.confirmarAjuste(tienda, arroz, d('46')))
          .called(1);
      verify(() => coordinador.confirmarAjuste(tienda, cafe, d('23')))
          .called(1);
      verifyNever(() => coordinador.confirmarAjuste(tienda, huevo, any()));
      expect(vm.aviso, 'Ajuste registrado en 2 productos');
    });

    test(
      'cantidad negativa: el mensaje del servicio queda en la fila',
      () async {
        ajusteResponde();
        when(() => coordinador.confirmarAjuste(tienda, cafe, d('-1')))
            .thenAnswer(
              (_) async => throw const ExcepcionCantidadContadaNegativa(),
            );
        await vm.cambiarCantidad(cafe, '-1');
        await vm.cambiarCantidad(arroz, '40');
        await vm.confirmar();

        expect(fila(cafe).error, 'La cantidad contada no puede ser negativa');
        expect(fila(cafe).contada, d('-1'));
        expect(fila(arroz).contado, isFalse);
        expect(vm.aviso, 'Ajuste registrado. Nuevo stock: 40');
      },
    );

    test('error al guardar: mensaje del diagrama y la fila sigue', () async {
      when(() => coordinador.confirmarAjuste(tienda, any(), any()))
          .thenAnswer((_) async => throw StateError('disco'));
      await vm.cambiarCantidad(huevo, '78');
      await vm.confirmar();

      expect(vm.error, 'No se pudo registrar el ajuste. Intente de nuevo');
      expect(fila(huevo).contada, d('78'));
      expect(vm.aviso, isNull);
      expect(vm.registrando, isFalse);
    });

    test('no confirma sin nada contado', () async {
      await vm.confirmar();
      verifyNever(() => coordinador.confirmarAjuste(any(), any(), any()));
    });
  });
}
