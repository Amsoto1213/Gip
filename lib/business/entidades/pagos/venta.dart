import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';

/// Venta del mostrador con sus formas de pago; se crea al confirmar (DA-27).
/// Sus salidas de inventario (`SalidaVenta`) son partes de la venta: la
/// navegación va de la salida a la venta (DA-60).
///
/// La anulación (`anular`, `isAnulada`, `getAnulacion`) llega con CUS-20.
class Venta {
  Venta(this._id, List<FormaPago> formasPago, this._total, this._fecha)
    : _formasPago = List.unmodifiable(formasPago);

  final String _id;
  final List<FormaPago> _formasPago;
  final Decimal _total;
  final DateTime _fecha;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  List<FormaPago> getFormasPago() => _formasPago;

  /// Total de la venta; lo calcula ServicioVentas.calcularTotal.
  Decimal getTotal() => _total;

  DateTime getFecha() => _fecha;
}
