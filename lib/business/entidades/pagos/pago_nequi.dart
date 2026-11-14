import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';

/// Pago por Nequi (transferencia): el dinero llega a la cuenta Nequi de la
/// tienda, no al efectivo de la caja (DA-63).
class PagoNequi extends FormaPago {
  PagoNequi(super.id, this._monto, this._referencia);

  final Decimal _monto;
  final String? _referencia;

  /// Monto pagado por Nequi.
  Decimal getMonto() => _monto;

  /// Número de la transacción que muestra Nequi, para cruzarlo con la app;
  /// puede quedar vacío.
  String? getReferencia() => _referencia;

  /// Devuelve getMonto() (DA-72).
  @override
  Decimal calcularMontoCubierto() => _monto;
}
