import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

void main() {
  test('la merma conserva su motivo, su cantidad con signo y nace VIGENTE', () {
    final producto = Producto(
      'p1',
      'LEC-1',
      'Leche bolsa 1 L',
      UnidadMedida.unidad,
      null,
      Decimal.fromInt(4200),
    );
    final item = ItemInventario('i1', producto, Decimal.fromInt(14));
    final fecha = DateTime.utc(2026, 11, 14);

    final merma = Merma(
      'm1',
      item,
      Decimal.fromInt(-2),
      fecha,
      MotivoMerma.vencido,
    );

    expect(merma.getId(), 'm1');
    expect(merma.getItem(), same(item));
    expect(merma.getCantidad(), Decimal.fromInt(-2));
    expect(merma.getFecha(), fecha);
    expect(merma.getMotivo(), MotivoMerma.vencido);
    expect(merma.getEstado(), EstadoMovimiento.vigente);
  });
}
