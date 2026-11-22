import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';

/// Etiqueta para pegar en un producto: el nombre y el precio del producto y el
/// código que se imprime. No se guarda; la crea `ServicioCatalogo` y la recibe
/// `IImpresionEtiquetas` (DA-39, DA-40, DA-41).
///
/// Recibe solo los datos que imprime; `ServicioCatalogo` los saca del
/// producto y de su código (DI-55, DI-60).
class Etiqueta {
  Etiqueta(this._nombre, this._precioVenta, this._valorCodigo, this._formato);

  final String _nombre;
  final Decimal _precioVenta;
  final String _valorCodigo;
  final FormatoCodigo _formato;

  /// Nombre del producto en el momento de armar la etiqueta.
  String getNombre() => _nombre;

  /// Precio de venta del producto en el momento de armar la etiqueta.
  Decimal getPrecioVenta() => _precioVenta;

  /// Texto exacto del código que se imprime (DA-41).
  String getValorCodigo() => _valorCodigo;

  /// Formato del código; dice si se dibuja QR o de barras.
  FormatoCodigo getFormato() => _formato;
}
