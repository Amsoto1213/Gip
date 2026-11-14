import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';

/// Entrada de mercancía de un producto, con su costo y, si hay, el número de
/// factura (RF-01, DA-11).
class EntradaMercancia extends MovimientoInventario {
  EntradaMercancia(
    super.id,
    super.item,
    super.cantidad,
    super.fecha,
    this._costoUnitario,
    this._numeroFactura,
  );

  final Decimal _costoUnitario;
  final String? _numeroFactura;

  Decimal getCostoUnitario() => _costoUnitario;

  /// Número de la factura del proveedor; nulo si llegó sin factura (IE-02).
  String? getNumeroFactura() => _numeroFactura;

  /// Information Expert: getCantidad() x getCostoUnitario() (RF-09, DA-72).
  Decimal calcularCostoTotal() => getCantidad() * _costoUnitario;
}
