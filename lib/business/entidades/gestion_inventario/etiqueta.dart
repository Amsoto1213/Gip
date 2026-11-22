import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';

/// Etiqueta para pegar en un producto: el nombre y el precio del producto y el
/// código que se imprime. No se guarda; la crea `ServicioCatalogo` y la recibe
/// `IImpresionEtiquetas` (DA-39, DA-40, DA-41).
///
/// Depende de [Producto] y [CodigoProducto] solo en el constructor: copia los
/// datos que se imprimen y no guarda referencias a ellos (DI-55).
class Etiqueta {
  Etiqueta(Producto producto, CodigoProducto codigo)
    : _nombre = producto.getNombre(),
      _precioVenta = producto.getPrecioVenta(),
      _valorCodigo = codigo.getValor(),
      _formato = codigo.getFormato();

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
