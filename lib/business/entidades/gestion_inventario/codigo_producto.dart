import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';

/// Código asociado a un producto: de barras (EAN-13, EAN-8, UPC-A) o QR.
/// [getValor] guarda el texto exacto que devuelve la lectura; un mismo valor no
/// se repite entre productos de una tienda (RF-06, DA-41).
class CodigoProducto {
  CodigoProducto(this._id, this._formato, this._valor);

  final String _id;
  final FormatoCodigo _formato;
  final String _valor;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  FormatoCodigo getFormato() => _formato;

  String getValor() => _valor;
}
