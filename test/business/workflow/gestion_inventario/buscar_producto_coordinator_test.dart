import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class ServicioCatalogoFalso extends Mock implements ServicioCatalogo {}

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );

  test('buscarPorNombre delega una vez en el servicio', () async {
    final servicio = ServicioCatalogoFalso();
    final coco = Producto(
      '22222222-2222-4222-8222-222222222222',
      'COCO',
      'Coco',
      UnidadMedida.unidad,
      null,
      Decimal.parse('3000'),
    );
    when(
      () => servicio.buscarPorNombre(tienda, 'co'),
    ).thenAnswer((_) async => [coco]);

    final resultado = await BuscarProductoCoordinator(
      servicio,
    ).buscarPorNombre(tienda, 'co');

    expect(resultado, [coco]);
    verify(() => servicio.buscarPorNombre(tienda, 'co')).called(1);
    verifyNoMoreInteractions(servicio);
  });
}
