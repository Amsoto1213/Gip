import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';

void main() {
  test('guarda el nombre, el precio y el código que recibe (DI-60)', () {
    final etiqueta = Etiqueta(
      'Galletas de coco x 6',
      Decimal.parse('3500'),
      '7701234567897',
      FormatoCodigo.ean13,
    );

    expect(etiqueta.getNombre(), 'Galletas de coco x 6');
    expect(etiqueta.getPrecioVenta(), Decimal.parse('3500'));
    expect(etiqueta.getValorCodigo(), '7701234567897');
    expect(etiqueta.getFormato(), FormatoCodigo.ean13);
  });
}
