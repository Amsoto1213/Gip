import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/consumo_promedio_simple.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);
  final coco = Producto(
    'p1',
    'C1',
    'Coco',
    UnidadMedida.unidad,
    null,
    d('3000'),
  );
  final item = ItemInventario('i1', coco, d('2'));
  final fecha = DateTime.utc(2026, 11, 10);
  final estrategia = ConsumoPromedioSimple();

  SalidaVenta salida(String cantidad) => SalidaVenta(
    'S$cantidad',
    item,
    d(cantidad),
    fecha,
    Venta('v', const [], d('0'), fecha),
    d('3000'),
    null,
  );
  VentaPerdida perdida(int n) => VentaPerdida('vp$n', coco, fecha);

  test(
    'suma las unidades vendidas en valor absoluto y divide entre los días',
    () {
      expect(
        estrategia.calcularConsumoDiario([salida('-4'), salida('-0.5')], [], 3),
        d('1.5'),
      );
    },
  );

  test('cada venta perdida cuenta como una unidad de demanda (RF-12)', () {
    expect(
      estrategia.calcularConsumoDiario(
        [salida('-6')],
        [perdida(1), perdida(2), perdida(3), perdida(4)],
        5,
      ),
      d('2'),
    );
  });

  test('solo con ventas perdidas también hay consumo', () {
    expect(estrategia.calcularConsumoDiario([], [perdida(1)], 4), d('0.25'));
  });

  test('sin ventas ni ventas perdidas el consumo es cero', () {
    expect(estrategia.calcularConsumoDiario([], [], 30), Decimal.zero);
  });

  test('sin días con datos es cero, sin dividir entre cero', () {
    expect(
      estrategia.calcularConsumoDiario([salida('-3')], [], 0),
      Decimal.zero,
    );
  });

  test('redondea a 4 decimales, mitad hacia arriba', () {
    expect(
      estrategia.calcularConsumoDiario([salida('-2')], [], 3),
      d('0.6667'),
    );
  });
}
