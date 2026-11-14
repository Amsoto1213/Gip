import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';

/// Pago de contado: el efectivo recibido y el cambio que se devuelve.
class PagoContado extends FormaPago {
  PagoContado(super.id, this._montoRecibido, this._cambio);

  final Decimal _montoRecibido;
  final Decimal _cambio;

  /// Efectivo que entregó el cliente.
  Decimal getMontoRecibido() => _montoRecibido;

  /// Efectivo que se le devuelve.
  Decimal getCambio() => _cambio;

  /// getMontoRecibido() - getCambio(): lo que queda en caja (DA-72).
  @override
  Decimal calcularMontoCubierto() => _montoRecibido - _cambio;
}
