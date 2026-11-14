import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:mocktail/mocktail.dart';

class ServicioVentasFalso extends Mock implements ServicioVentas {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  final arroz = Producto(
    'p1',
    'ARR',
    'Arroz',
    UnidadMedida.unidad,
    null,
    d('2800'),
  );
  final linea = LineaVenta(ItemInventario('i1', arroz, d('10')), d('2'));

  late ServicioVentasFalso servicio;
  late RegistrarVentaCoordinator coordinador;

  setUp(() {
    servicio = ServicioVentasFalso();
    coordinador = RegistrarVentaCoordinator(servicio);
  });

  test('agregarProducto delega en agregarLinea', () async {
    final lineas = <LineaVenta>[];
    when(() => servicio.agregarLinea(tienda, lineas, arroz, d('2')))
        .thenAnswer((_) async => linea);

    expect(
      await coordinador.agregarProducto(tienda, lineas, arroz, d('2')),
      same(linea),
    );
  });

  test('agregarProducto deja pasar el error de existencia', () async {
    when(() => servicio.agregarLinea(tienda, [], arroz, d('99')))
        .thenAnswer((_) async => throw const ExcepcionExistenciaInsuficiente());

    await expectLater(
      coordinador.agregarProducto(tienda, [], arroz, d('99')),
      throwsA(isA<ExcepcionExistenciaInsuficiente>()),
    );
  });

  test('cambiarCantidad y obtenerTotal delegan', () {
    when(() => servicio.calcularTotal([linea])).thenReturn(d('5600'));

    coordinador.cambiarCantidad(linea, d('3'));

    verify(() => servicio.cambiarCantidad(linea, d('3'))).called(1);
    expect(coordinador.obtenerTotal([linea]), d('5600'));
  });

  test('pagarDeContado y pagarConNequi delegan', () {
    final contado = PagoContado('c', d('20000'), d('6600'));
    final nequi = PagoNequi('n', d('5000'), '4471');
    when(() => servicio.crearPagoContado(d('13400'), d('20000')))
        .thenReturn(contado);
    when(() => servicio.crearPagoNequi(d('5000'), '4471')).thenReturn(nequi);

    expect(coordinador.pagarDeContado(d('13400'), d('20000')), same(contado));
    expect(coordinador.pagarConNequi(d('5000'), '4471'), same(nequi));
  });

  test('confirmarVenta delega en confirmar', () async {
    final formas = <FormaPago>[PagoNequi('n', d('5600'), null)];
    final venta = Venta('v1', formas, d('5600'), DateTime.utc(2026));
    when(() => servicio.confirmar(tienda, [linea], formas))
        .thenAnswer((_) async => venta);

    expect(
      await coordinador.confirmarVenta(tienda, [linea], formas),
      same(venta),
    );
  });
}
