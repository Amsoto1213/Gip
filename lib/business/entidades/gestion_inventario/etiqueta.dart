import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';

/// Etiqueta para pegar en un producto: apunta al producto (nombre y precio) y
/// al código que se imprime. No se guarda; la crea `ServicioCatalogo` y la
/// recibe `IImpresionEtiquetas` (DA-39, DA-40, DA-41).
class Etiqueta {
  Etiqueta(this._producto, this._codigo);

  final Producto _producto;
  final CodigoProducto _codigo;

  Producto getProducto() => _producto;

  /// Código que se imprime; su formato dice si es QR o de barras.
  CodigoProducto getCodigo() => _codigo;
}
