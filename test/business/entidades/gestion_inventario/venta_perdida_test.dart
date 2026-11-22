import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';

void main() {
  test('copia el id y el nombre del producto (DI-58)', () {
    final coco = Producto(
      'p1',
      'C1',
      'Coco',
      UnidadMedida.unidad,
      null,
      Decimal.parse('3000'),
    );
    final fecha = DateTime.utc(2026, 11, 22, 9);

    final venta = VentaPerdida('vp1', coco, fecha);

    expect(venta.getId(), 'vp1');
    expect(venta.getProductoId(), 'p1');
    expect(venta.getNombreProducto(), 'Coco');
    expect(venta.getFecha(), fecha);
  });
}
