import 'dart:typed_data';

import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Protected Variations: arma el PDF de etiquetas en hojas adhesivas tamaño
/// carta (3 columnas por 10 filas, 30 por hoja) y abre la impresión del
/// dispositivo; no requiere hardware especial (CUS-18, DA-39).
class ImpresionEtiquetasPdf implements IImpresionEtiquetas {
  /// [abrirImpresion] recibe el PDF ya armado; por defecto abre el diálogo de
  /// impresión de `printing` (en la web, el del navegador).
  ImpresionEtiquetasPdf({
    Future<void> Function(Uint8List pdf, String nombre)? abrirImpresion,
  }) : _abrirImpresion = abrirImpresion ?? _abrirConPrinting;

  final Future<void> Function(Uint8List pdf, String nombre) _abrirImpresion;

  static const int columnas = 3;
  static const int filas = 10;
  static const int etiquetasPorHoja = columnas * filas;

  static final double _ancho = 2.625 * PdfPageFormat.inch;
  static final double _alto = 1 * PdfPageFormat.inch;
  static final double _margenSuperior = 0.5 * PdfPageFormat.inch;
  static final double _margenLateral = 0.1875 * PdfPageFormat.inch;
  static final double _separacion = 0.125 * PdfPageFormat.inch;

  static Future<void> _abrirConPrinting(Uint8List pdf, String nombre) =>
      Printing.layoutPdf(name: nombre, onLayout: (_) async => pdf);

  @override
  Future<void> imprimir(List<Etiqueta> etiquetas) async {
    final pdf = await armarPdf(etiquetas);
    await _abrirImpresion(pdf, 'Etiquetas GIP');
  }

  /// Arma el PDF: una página carta por cada 30 etiquetas.
  Future<Uint8List> armarPdf(List<Etiqueta> etiquetas) async {
    final documento = pw.Document(title: 'Etiquetas GIP', creator: 'GIP');
    for (var i = 0; i < etiquetas.length; i += etiquetasPorHoja) {
      final hoja = etiquetas.skip(i).take(etiquetasPorHoja).toList();
      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.only(
            left: _margenLateral,
            top: _margenSuperior,
          ),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var f = 0; f < filas; f++)
                if (f * columnas < hoja.length)
                  pw.Row(
                    children: [
                      for (var c = 0; c < columnas; c++)
                        if (f * columnas + c < hoja.length)
                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                              right: c < columnas - 1 ? _separacion : 0,
                            ),
                            child: _celda(hoja[f * columnas + c]),
                          ),
                    ],
                  ),
            ],
          ),
        ),
      );
    }
    return documento.save();
  }

  pw.Widget _celda(Etiqueta etiqueta) {
    return pw.Container(
      width: _ancho,
      height: _alto,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: etiqueta.getFormato() == FormatoCodigo.qr ? 54 : 84,
            height: 54,
            child: pw.BarcodeWidget(
              barcode: _barcodeDe(etiqueta.getFormato()),
              data: etiqueta.getValorCodigo(),
              drawText: false,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  etiqueta.getNombre(),
                  maxLines: 2,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  r'$ ' + _precio(etiqueta.getPrecioVenta().toString()),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Barcode _barcodeDe(FormatoCodigo formato) => switch (formato) {
    FormatoCodigo.ean13 => pw.Barcode.ean13(),
    FormatoCodigo.ean8 => pw.Barcode.ean8(),
    FormatoCodigo.upca => pw.Barcode.upcA(),
    FormatoCodigo.qr => pw.Barcode.qrCode(),
  };

  /// Miles con punto y decimales con coma (3500.5 → "3.500,5").
  String _precio(String valor) {
    final partes = valor.split('.');
    final entero = partes.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return partes.length > 1 ? '$entero,${partes[1]}' : entero;
  }
}
