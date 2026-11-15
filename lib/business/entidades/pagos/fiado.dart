import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';

/// Venta a crédito con su saldo pendiente; es una forma de pago de la venta
/// (DA-04, DA-20). Se crea en memoria con saldo = monto y estado PENDIENTE y se
/// guarda al confirmar la venta (CUS-07).
///
/// Los abonos (`registrarAbono`, `recalcularSaldo`) llegan con CUS-08 y
/// `anular` con CUS-20 (DI-26).
class Fiado extends FormaPago {
  Fiado(super.id, this._montoInicial, this._fechaInicio, this._cliente)
    : _saldoPendiente = _montoInicial,
      _estado = EstadoFiado.pendiente;

  /// Fiado leído de la base, con el saldo y el estado guardados.
  Fiado.guardado(
    super.id,
    this._montoInicial,
    this._fechaInicio,
    this._cliente,
    this._saldoPendiente,
    this._estado,
  );

  final Decimal _montoInicial;
  final DateTime _fechaInicio;
  final Cliente _cliente;
  final Decimal _saldoPendiente;
  final EstadoFiado _estado;

  /// Cliente que debe el fiado.
  Cliente getCliente() => _cliente;

  /// Lo que la venta quedó debiendo.
  Decimal getMontoInicial() => _montoInicial;

  /// Lo que falta por pagar.
  Decimal getSaldoPendiente() => _saldoPendiente;

  EstadoFiado getEstado() => _estado;

  DateTime getFechaInicio() => _fechaInicio;

  /// Devuelve getMontoInicial(): lo que la venta quedó debiendo (DA-72).
  @override
  Decimal calcularMontoCubierto() => _montoInicial;
}
