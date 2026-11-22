import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);

  late Producto coco;
  late ItemInventario item;
  late AlertaReabastecimiento alerta;

  setUp(() {
    coco = Producto('p1', 'C1', 'Coco', UnidadMedida.unidad, null, d('3000'));
    item = ItemInventario('i1', coco, d('4'));
    alerta = AlertaReabastecimiento(
      'a1',
      item,
      DateTime(2026, 11, 22),
      d('4'),
      d('2'),
      d('2'),
      false,
    );
  });

  test('copia el id del ítem y el id y el nombre de su producto', () {
    expect(alerta.getItemId(), 'i1');
    expect(alerta.getProductoId(), 'p1');
    expect(alerta.getNombreProducto(), 'Coco');
    expect(alerta.getExistencia(), d('4'));
  });

  test('no cambia si después cambia el stock del ítem (DI-57, RNF-02)', () {
    item.setStockActual(d('30'));

    expect(alerta.getExistencia(), d('4'));
    expect(alerta.getItemId(), 'i1');
  });
}
