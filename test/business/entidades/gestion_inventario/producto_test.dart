import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
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

  test('nace sin códigos y con actualizadoEn en UTC', () {
    final producto = galletas();
    expect(producto.getCodigos(), isEmpty);
    expect(producto.getActualizadoEn().isUtc, isTrue);
  });

  test('setActualizadoEn guarda la fecha en UTC', () {
    final producto = galletas();
    final local = DateTime(2026, 11, 14, 18, 30);
    producto.setActualizadoEn(local);
    expect(producto.getActualizadoEn().isUtc, isTrue);
    expect(producto.getActualizadoEn(), local.toUtc());
  });

  test('agrega y quita códigos; la lista expuesta no se puede modificar', () {
    final producto = galletas();
    final codigo = CodigoProducto('c1', FormatoCodigo.ean13, '7709876543210');
    producto.agregarCodigo(codigo);
    expect(producto.getCodigos().single.getValor(), '7709876543210');
    expect(() => producto.getCodigos().add(codigo), throwsUnsupportedError);

    producto.quitarCodigo(codigo);
    expect(producto.getCodigos(), isEmpty);
  });

  test('el precio de compra puede ser nulo', () {
    final producto = galletas()..setPrecioCompra(null);
    expect(producto.getPrecioCompra(), isNull);
  });

  group('cambiarCodigoInterno (CUS-22, DI-45)', () {
    test('cambia el código interno y no toca lo demás', () {
      final producto = galletas()
        ..agregarCodigo(
          CodigoProducto('c1', FormatoCodigo.ean13, '7701234567895'),
        );

      producto.cambiarCodigoInterno('GAL-6-2');

      expect(producto.getCodigo(), 'GAL-6-2');
      expect(producto.getNombre(), 'Galletas de coco x 6');
      expect(producto.getCodigos(), hasLength(1));
    });

    test('se puede volver a cambiar', () {
      final producto = galletas()
        ..cambiarCodigoInterno('GAL-6-2')
        ..cambiarCodigoInterno('GAL-6-3');

      expect(producto.getCodigo(), 'GAL-6-3');
    });
  });
}
