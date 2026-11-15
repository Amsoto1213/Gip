import 'package:gip/business/entidades/gestion_inventario/producto.dart';

/// Venta que no se realizó porque el producto estaba agotado (RF-12). Solo se
/// agrega: el número de ventas perdidas de un periodo se obtiene contando los
/// registros (DA-48, DA-50). Se registra con CUS-13 (DI-30); CUS-24 y CUS-05 solo
/// las leen (DI-25).
class VentaPerdida {
  VentaPerdida(this._id, this._producto, this._fecha);

  final String _id;
  final Producto _producto;
  final DateTime _fecha;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  Producto getProducto() => _producto;

  /// Fecha y hora en que el cliente pidió el producto agotado.
  DateTime getFecha() => _fecha;
}
