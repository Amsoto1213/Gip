import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';

/// Stock de un producto en la tienda; lo mantiene `ServicioInventario` sumando
/// los movimientos (DA-19). Es parte del [Producto] (composición): se crea con
/// él y se guarda con su propio repositorio (DA-60).
class ItemInventario {
  ItemInventario(this._id, this._producto, this._stockActual);

  final String _id;
  final Producto _producto;
  final Decimal _stockActual;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  Producto getProducto() => _producto;

  Decimal getStockActual() => _stockActual;
}
