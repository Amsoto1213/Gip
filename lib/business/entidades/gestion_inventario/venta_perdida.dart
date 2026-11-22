import 'package:gip/business/entidades/gestion_inventario/producto.dart';

/// Venta que no se realizó porque el producto estaba agotado (RF-12). Solo se
/// agrega: el número de ventas perdidas de un periodo se obtiene contando los
/// registros (DA-48, DA-50). Se registra con CUS-13 (DI-30); CUS-24 y CUS-05 solo
/// las leen (DI-25).
///
/// Depende de [Producto] solo en el constructor: copia su id y su nombre y no
/// guarda el producto (DI-58).
class VentaPerdida {
  VentaPerdida(this._id, Producto producto, this._fecha)
    : _productoId = producto.getId(),
      _nombreProducto = producto.getNombre();

  final String _id;
  final String _productoId;
  final String _nombreProducto;
  final DateTime _fecha;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Id del producto que se pidió agotado.
  String getProductoId() => _productoId;

  /// Nombre del producto que se pidió agotado.
  String getNombreProducto() => _nombreProducto;

  /// Fecha y hora en que el cliente pidió el producto agotado.
  DateTime getFecha() => _fecha;
}
