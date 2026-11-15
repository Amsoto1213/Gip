import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';

/// Pago parcial o total de un fiado, en efectivo o por Nequi. No tiene cambio:
/// un abono mayor al saldo se rechaza (IE-06). Solo se agrega; si hay que
/// deshacerlo se marca como anulado, nunca se borra (RNF-15).
///
/// `getMonto` y `getFecha` no están en EA; sin ellos el repositorio y la
/// pantalla no pueden leer el abono (DI-27).
class Abono {
  Abono(
    this._id,
    this._monto,
    this._fecha,
    this._medio,
    this._referencia, {
    this._anulado = false,
  });

  final String _id;
  final Decimal _monto;
  final DateTime _fecha;
  final MedioPago _medio;
  final String? _referencia;
  bool _anulado;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  Decimal getMonto() => _monto;

  /// Fecha y hora en UTC.
  DateTime getFecha() => _fecha;

  /// Medio con que se pagó.
  MedioPago getMedio() => _medio;

  /// Referencia de Nequi, o nula.
  String? getReferencia() => _referencia;

  /// Information Expert: verdadero si el medio es EFECTIVO; solo esos abonos
  /// entran a la caja.
  bool esEfectivo() => _medio == MedioPago.efectivo;

  bool isAnulado() => _anulado;

  /// Information Expert: rechaza si ya está anulado; si no, queda anulado.
  void anular() {
    if (_anulado) throw StateError('El abono ya está anulado');
    _anulado = true;
  }
}
