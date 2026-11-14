import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);

  ItemInventario item({String? compra = '2000', String venta = '2800'}) =>
      ItemInventario(
        'i1',
        Producto(
          'p1',
          'ARR',
          'Arroz 500 g',
          UnidadMedida.unidad,
          compra == null ? null : d(compra),
          d(venta),
        ),
        d('10'),
      );

  group('LineaVenta.calcularSubtotal', () {
    test('cantidad x precio de venta actual', () {
      final linea = LineaVenta(item(), d('2'));
      expect(linea.calcularSubtotal(), d('5600'));
    });

    test('usa el precio actual si cambia antes de confirmar (DA-61)', () {
      final linea = LineaVenta(item(), d('3'));
      linea.getItem().getProducto().setPrecioVenta(d('3000'));
      expect(linea.calcularSubtotal(), d('9000'));
    });

    test('cantidades con decimales (kilos)', () {
      final linea = LineaVenta(item(venta: '9000'), d('1.5'));
      expect(linea.calcularSubtotal(), d('13500'));
    });
  });

  group('calcularMontoCubierto (DA-72)', () {
    test('contado: recibido - cambio', () {
      final pago = PagoContado('f1', d('50000'), d('18000'));
      expect(pago.calcularMontoCubierto(), d('32000'));
    });

    test('Nequi: el monto', () {
      expect(
        PagoNequi('f2', d('20000'), '4471').calcularMontoCubierto(),
        d('20000'),
      );
    });
  });

  group('SalidaVenta', () {
    final venta = Venta('v1', const [], d('5600'), DateTime.utc(2026));

    test('calcularUnidades es el valor absoluto de la cantidad', () {
      final s = SalidaVenta(
        's1',
        item(),
        d('-2'),
        DateTime.utc(2026),
        venta,
        d('2800'),
        d('2000'),
      );
      expect(s.calcularUnidades(), d('2'));
      expect(s.calcularMargen(), d('1600'));
      expect(s.getVenta(), same(venta));
    });

    test('calcularMargen es null sin costo (ERS 3.2.4)', () {
      final s = SalidaVenta(
        's1',
        item(compra: null),
        d('-2'),
        DateTime.utc(2026),
        venta,
        d('2800'),
        null,
      );
      expect(s.calcularMargen(), isNull);
    });
  });
}
