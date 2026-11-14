import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Salida de stock por una venta; cantidad negativa. Guarda el precio de venta
/// y el costo del producto en el momento de la venta, para que los reportes no
/// cambien si después se editan los precios (DA-61).
class SalidaVenta extends MovimientoInventario {
  SalidaVenta(
    super.id,
    super.item,
    super.cantidad,
    super.fecha,
    this._venta,
    this._precioUnitario,
    this._costoUnitario,
  );

  final Venta _venta;
  final Decimal _precioUnitario;
  final Decimal? _costoUnitario;

  /// Venta de la que es parte (composición, DA-60).
  Venta getVenta() => _venta;

  /// Precio al que se vendió (DA-61).
  Decimal getPrecioUnitario() => _precioUnitario;

  /// Costo con que se vendió, o nulo si no estaba registrado (ERS 3.2.4).
  Decimal? getCostoUnitario() => _costoUnitario;

  /// Information Expert: unidades vendidas, |getCantidad()| (RF-11, DA-72).
  Decimal calcularUnidades() => getCantidad().abs();

  /// Information Expert: (precio - costo) x unidades; null si no hay costo,
  /// porque el dato está incompleto (RF-08, ERS 3.2.4, DA-61, DA-72).
  Decimal? calcularMargen() {
    final costo = _costoUnitario;
    if (costo == null) return null;
    return (_precioUnitario - costo) * calcularUnidades();
  }
}
