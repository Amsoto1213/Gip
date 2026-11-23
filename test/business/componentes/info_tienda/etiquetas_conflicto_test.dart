import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/etiquetas_conflicto.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);

  group('hora', () {
    for (final (h, m, texto) in [
      (0, 5, '12:05 a. m.'),
      (9, 30, '9:30 a. m.'),
      (12, 0, '12:00 p. m.'),
      (13, 7, '1:07 p. m.'),
      (23, 59, '11:59 p. m.'),
    ]) {
      test(texto, () {
        expect(EtiquetasConflicto.hora(DateTime(2026, 11, 19, h, m)), texto);
      });
    }

    test('diaYHora lleva el día y el mes con dos cifras', () {
      expect(
        EtiquetasConflicto.diaYHora(DateTime(2026, 3, 4, 10, 42)),
        '04/03 10:42 a. m.',
      );
    });
  });

  group('pesos', () {
    for (final (valor, texto) in [
      ('0', r'$ 0'),
      ('950', r'$ 950'),
      ('8000', r'$ 8.000'),
      ('1250000', r'$ 1.250.000'),
      ('8000.60', r'$ 8.001'),
      ('-6000', r'-$ 6.000'),
    ]) {
      test('$valor → $texto', () {
        expect(EtiquetasConflicto.pesos(d(valor)), texto);
      });
    }
  });

  test('cantidad no deja ceros de más', () {
    expect(EtiquetasConflicto.cantidad(d('24.000')), '24');
    expect(EtiquetasConflicto.cantidad(d('2.5')), '2.5');
  });

  group('movimiento', () {
    final item = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('10'),
    );
    final fecha = DateTime(2026, 11, 19, 10, 42).toUtc();

    test('entrada con factura', () {
      expect(
        EtiquetasConflicto.movimiento(
          EntradaMercancia('e1', item, d('24'), fecha, d('400'), ' FV-10231 '),
        ),
        'Entrada de 24 Huevo AA · factura FV-10231 · 19/11 10:42 a. m.',
      );
    });

    test('entrada sin factura', () {
      expect(
        EtiquetasConflicto.movimiento(
          EntradaMercancia('e1', item, d('24'), fecha, d('400'), null),
        ),
        'Entrada de 24 Huevo AA · 19/11 10:42 a. m.',
      );
    });

    test('venta, pérdida y conteo usan la cantidad sin signo', () {
      expect(
        EtiquetasConflicto.movimiento(
          SalidaVenta('s1', item, -d('3'), fecha, 'v1', d('550'), d('400')),
        ),
        'Venta de 3 Huevo AA · 19/11 10:42 a. m.',
      );
      expect(
        EtiquetasConflicto.movimiento(
          Merma('m1', item, -d('2'), fecha, MotivoMerma.vencido),
        ),
        'Pérdida de 2 Huevo AA · 19/11 10:42 a. m.',
      );
      expect(
        EtiquetasConflicto.movimiento(
          AjusteConteo('a1', item, -d('1'), fecha, d('9')),
        ),
        'Conteo de Huevo AA · 19/11 10:42 a. m.',
      );
    });
  });

  test('abono en efectivo y por Nequi', () {
    final fecha = DateTime(2026, 11, 19, 15, 5).toUtc();
    expect(
      EtiquetasConflicto.abono(
        Abono('a1', d('8000'), fecha, MedioPago.efectivo, null),
      ),
      r'Abono de $ 8.000 en efectivo · 19/11 3:05 p. m.',
    );
    expect(
      EtiquetasConflicto.abono(
        Abono('a2', d('8000'), fecha, MedioPago.nequi, 'ref'),
      ),
      r'Abono de $ 8.000 por Nequi · 19/11 3:05 p. m.',
    );
  });
}
