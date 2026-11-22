import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

void main() {
  Producto galletas() => Producto(
    'p1',
    'GAL-6',
    'Galletas de coco x 6',
    UnidadMedida.unidad,
    Decimal.parse('2600'),
    Decimal.parse('3500'),
  );

  test('copia el nombre, el precio y el código que se imprimen', () {
    final etiqueta = Etiqueta(
      galletas(),
      CodigoProducto('c1', FormatoCodigo.ean13, '7701234567897'),
    );

    expect(etiqueta.getNombre(), 'Galletas de coco x 6');
    expect(etiqueta.getPrecioVenta(), Decimal.parse('3500'));
    expect(etiqueta.getValorCodigo(), '7701234567897');
    expect(etiqueta.getFormato(), FormatoCodigo.ean13);
  });

  test('no cambia si después se edita el producto (DI-55)', () {
    final producto = galletas();
    final etiqueta = Etiqueta(
      producto,
      CodigoProducto('c1', FormatoCodigo.qr, 'GIP:GAL-6'),
    );

    producto
      ..setNombre('Galletas de coco x 12')
      ..setPrecioVenta(Decimal.parse('6800'));

    expect(etiqueta.getNombre(), 'Galletas de coco x 6');
    expect(etiqueta.getPrecioVenta(), Decimal.parse('3500'));
  });
}
