import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);

  test('guarda el id del ítem y el id y el nombre del producto que recibe '
      '(DI-60)', () {
    final alerta = AlertaReabastecimiento(
      'a1',
      'i1',
      'p1',
      'Coco',
      DateTime(2026, 11, 22),
      d('4'),
      d('2'),
      d('2'),
      false,
    );

    expect(alerta.getItemId(), 'i1');
    expect(alerta.getProductoId(), 'p1');
    expect(alerta.getNombreProducto(), 'Coco');
    expect(alerta.getExistencia(), d('4'));
    expect(alerta.getDiasCobertura(), d('2'));
    expect(alerta.isProvisional(), isFalse);
  });
}
