import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/data/service_agents/impresion_etiquetas_pdf.dart';

void main() {
  final galletas = Producto(
    'p1',
    'GAL-6',
    'Galletas de coco x 6',
    UnidadMedida.unidad,
    Decimal.parse('2600'),
    Decimal.parse('3500'),
  );

  Etiqueta etiqueta(FormatoCodigo formato, String valor) =>
      Etiqueta(galletas.getNombre(), galletas.getPrecioVenta(), valor, formato);

  int paginas(Uint8List pdf) =>
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(pdf)).length;

  test('arma un PDF válido con una hoja carta para 30 etiquetas', () async {
    final pdf = await ImpresionEtiquetasPdf().armarPdf([
      for (var i = 0; i < ImpresionEtiquetasPdf.etiquetasPorHoja; i++)
        etiqueta(FormatoCodigo.qr, 'GIP:GAL-6'),
    ]);

    expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
    expect(paginas(pdf), 1);
  });

  test('31 etiquetas pasan a una segunda hoja', () async {
    final pdf = await ImpresionEtiquetasPdf().armarPdf([
      for (var i = 0; i < 31; i++) etiqueta(FormatoCodigo.qr, 'GIP:GAL-6'),
    ]);

    expect(paginas(pdf), 2);
  });

  test('dibuja cada formato de código sin fallar', () async {
    final pdf = await ImpresionEtiquetasPdf().armarPdf([
      etiqueta(FormatoCodigo.ean13, '7701234567897'),
      etiqueta(FormatoCodigo.ean8, '96385074'),
      etiqueta(FormatoCodigo.upca, '036000291452'),
      etiqueta(FormatoCodigo.qr, 'GIP:GAL-6'),
    ]);

    expect(pdf, isNotEmpty);
  });

  test(
    'imprimir entrega el PDF armado a la impresión del dispositivo',
    () async {
      Uint8List? recibido;
      final impresion = ImpresionEtiquetasPdf(
        abrirImpresion: (pdf, nombre) async => recibido = pdf,
      );

      await impresion.imprimir([etiqueta(FormatoCodigo.qr, 'GIP:GAL-6')]);

      expect(recibido, isNotNull);
      expect(latin1.decode(recibido!.sublist(0, 5)), '%PDF-');
    },
  );
}
