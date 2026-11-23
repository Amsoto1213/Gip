import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';

void main() {
  test('guarda el id y el nombre del producto que recibe (DI-60)', () {
    final fecha = DateTime.utc(2026, 11, 22, 9);

    final venta = VentaPerdida('vp1', 'p1', 'Coco', fecha);

    expect(venta.getId(), 'vp1');
    expect(venta.getProductoId(), 'p1');
    expect(venta.getNombreProducto(), 'Coco');
    expect(venta.getFecha(), fecha);
  });
}
