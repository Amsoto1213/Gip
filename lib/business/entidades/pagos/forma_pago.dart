import 'package:decimal/decimal.dart';

/// Forma de pago de una venta: contado, Nequi o fiado; una venta tiene de una
/// a tres, sin repetir tipo. Polymorphism y Protected Variations (DA-20,
/// DA-63).
abstract class FormaPago {
  FormaPago(this._id);

  final String _id;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Polymorphism e Information Expert: parte del total de la venta que cubre
  /// esta forma de pago; cada subclase la calcula con sus datos (DA-72).
  Decimal calcularMontoCubierto();
}
