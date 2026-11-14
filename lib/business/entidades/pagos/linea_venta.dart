import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';

/// Una línea de la venta en curso (ítem y cantidad). Las líneas forman una
/// lista que conserva la pantalla; no se guarda: al confirmar, cada línea se
/// convierte en una `SalidaVenta` (DA-27, DA-40, DA-57).
class LineaVenta {
  LineaVenta(this._item, this._cantidad);

  final ItemInventario _item;
  Decimal _cantidad;

  /// Ítem del producto vendido.
  ItemInventario getItem() => _item;

  /// Cantidad pedida, positiva.
  Decimal getCantidad() => _cantidad;

  /// Cambia la cantidad antes de confirmar.
  void setCantidad(Decimal cantidad) => _cantidad = cantidad;

  /// Information Expert: cantidad x precio de venta actual del producto,
  /// porque la venta aún no se confirma (DA-61).
  Decimal calcularSubtotal() =>
      _cantidad * _item.getProducto().getPrecioVenta();
}
