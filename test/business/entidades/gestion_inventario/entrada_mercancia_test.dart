import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

void main() {
  final item = ItemInventario(
    'i1',
    Producto(
      'p1',
      'ACE-1',
      'Aceite 1 L',
      UnidadMedida.unidad,
      null,
      Decimal.parse('11000'),
    ),
    Decimal.parse('8'),
  );

  EntradaMercancia entrada() => EntradaMercancia(
    'e1',
    item,
    Decimal.parse('24'),
    DateTime.utc(2026, 11, 2),
    Decimal.parse('9400'),
    null,
  );

  test('nace VIGENTE y el estado se puede cambiar', () {
    final e = entrada();
    expect(e.getEstado(), EstadoMovimiento.vigente);
    e.setEstado(EstadoMovimiento.anulado);
    expect(e.getEstado(), EstadoMovimiento.anulado);
  });

  test('calcularCostoTotal = cantidad x costo unitario', () {
    expect(entrada().calcularCostoTotal(), Decimal.parse('225600'));
  });

  test('calcularCostoTotal con cantidad decimal', () {
    final e = EntradaMercancia(
      'e2',
      item,
      Decimal.parse('2.5'),
      DateTime.utc(2026),
      Decimal.parse('3000'),
      'FV-1',
    );
    expect(e.calcularCostoTotal(), Decimal.parse('7500'));
    expect(e.getNumeroFactura(), 'FV-1');
  });

  test('ItemInventario.setStockActual cambia el stock', () {
    final i = ItemInventario('i2', item.getProducto(), Decimal.zero)
      ..setStockActual(Decimal.parse('3'));
    expect(i.getStockActual(), Decimal.parse('3'));
  });
}
