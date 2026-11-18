import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_barras.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_qr.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

import 'fakes_catalogo.dart';

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );

  late ProductoRepositorioFalso productos;
  late InterpreteCodigoBarras barras;
  late InterpreteCodigoQR qr;

  setUp(() {
    productos = ProductoRepositorioFalso();
    barras = InterpreteCodigoBarras(productos);
    qr = InterpreteCodigoQR(productos);
  });

  group('InterpreteCodigoBarras', () {
    for (final (formato, lectura, esperado) in [
      ('EAN-13', '7701234567897', FormatoCodigo.ean13),
      ('EAN-13', '4006381333931', FormatoCodigo.ean13),
      ('EAN-8', '96385074', FormatoCodigo.ean8),
      ('EAN-8', '77012340', FormatoCodigo.ean8),
      ('UPC-A', '036000291452', FormatoCodigo.upca),
    ]) {
      test('reconoce $formato $lectura y deduce su formato', () {
        expect(barras.reconoce(lectura), isTrue);
        expect(barras.formatoDe(lectura), esperado);
      });
    }

    for (final (caso, lectura) in [
      ('EAN-13 con dígito de control errado', '7701234567890'),
      ('EAN-8 con dígito de control errado', '96385075'),
      ('UPC-A con dígito de control errado', '036000291453'),
      ('longitud que no es 8, 12 ni 13', '1234567'),
      ('14 dígitos', '17701234567894'),
      ('letras', 'GIP:ARR-1'),
      ('espacios en medio', '7701234 567897'),
      ('texto vacío', ''),
    ]) {
      test('no reconoce $caso', () {
        expect(barras.reconoce(lectura), isFalse);
      });
    }

    test('formatoDe rechaza una lectura que no reconoce', () {
      expect(() => barras.formatoDe('GIP:ARR-1'), throwsArgumentError);
    });

    test('buscar llama a buscarPorCodigoProducto con la lectura', () async {
      final leche =
          Producto(
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'LEC-1',
            'Leche bolsa 1 L',
            UnidadMedida.unidad,
            null,
            Decimal.parse('4200'),
          )..agregarCodigo(
            CodigoProducto(
              'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              FormatoCodigo.ean13,
              '7701234567897',
            ),
          );
      await productos.guardar(tienda, leche);

      expect(await barras.buscar(tienda, '7701234567897'), leche);
      expect(await barras.buscar(tienda, '4006381333931'), isNull);
      expect(productos.valoresBuscados, ['7701234567897', '4006381333931']);
    });
  });

  group('InterpreteCodigoQR', () {
    test('reconoce cualquier texto que no sea un EAN o UPC válido', () {
      expect(qr.reconoce('GIP:ARR-1'), isTrue);
      expect(qr.reconoce('https://fabrica.example/p/123'), isTrue);
      expect(qr.reconoce('7701234567890'), isTrue, reason: 'control errado');
      expect(qr.reconoce('7701234567897'), isFalse);
      expect(qr.reconoce('96385074'), isFalse);
    });

    test('el formato siempre es QR', () {
      expect(qr.formatoDe('GIP:ARR-1'), FormatoCodigo.qr);
    });

    test('busca el texto exacto, sin quitar el prefijo GIP:', () async {
      await qr.buscar(tienda, 'GIP:ARR-1');
      expect(productos.valoresBuscados, ['GIP:ARR-1']);
    });
  });
}
