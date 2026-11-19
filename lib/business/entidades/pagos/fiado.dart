import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

/// Venta a crédito con su saldo pendiente; es una forma de pago de la venta
/// (DA-04, DA-20). Se crea en memoria con saldo = monto y estado PENDIENTE y se
/// guarda al confirmar la venta (CUS-07).
///
/// `recalcularSaldo` llega con la conciliación (CUS-23, DI-27).
class Fiado extends FormaPago {
  Fiado(super.id, this._montoInicial, this._fechaInicio, this._cliente)
    : _saldoPendiente = _montoInicial,
      _estado = EstadoFiado.pendiente,
      _abonos = [];

  /// Fiado leído de la base, con el saldo y el estado guardados.
  Fiado.guardado(
    super.id,
    this._montoInicial,
    this._fechaInicio,
    this._cliente,
    this._saldoPendiente,
    this._estado, [
    List<Abono> abonos = const [],
  ]) : _abonos = List.of(abonos);

  final Decimal _montoInicial;
  final DateTime _fechaInicio;
  final Cliente _cliente;
  final List<Abono> _abonos;
  Decimal _saldoPendiente;
  EstadoFiado _estado;

  /// Cliente que debe el fiado.
  Cliente getCliente() => _cliente;

  /// Lo que la venta quedó debiendo.
  Decimal getMontoInicial() => _montoInicial;

  /// Lo que falta por pagar.
  Decimal getSaldoPendiente() => _saldoPendiente;

  EstadoFiado getEstado() => _estado;

  DateTime getFechaInicio() => _fechaInicio;

  /// Abonos del fiado, del más antiguo al más reciente.
  List<Abono> getAbonos() => List.unmodifiable(_abonos);

  /// Information Expert: agrega el abono, baja el saldo y pasa a SALDADO si
  /// llega a cero (RN-05). El servicio ya validó el monto (IE-06); aquí se
  /// rechaza de nuevo un monto que no sea positivo o pase del saldo, para no
  /// dejar el fiado en un estado imposible.
  Abono registrarAbono(Abono abono) {
    final monto = abono.getMonto();
    if (_estado != EstadoFiado.pendiente ||
        monto <= Decimal.zero ||
        monto > _saldoPendiente) {
      throw const ExcepcionMontoAbonoNoValido();
    }
    _abonos.add(abono);
    _saldoPendiente -= monto;
    if (_saldoPendiente == Decimal.zero) _estado = EstadoFiado.saldado;
    return abono;
  }

  /// Devuelve getMontoInicial(): lo que la venta quedó debiendo (DA-72).
  @override
  Decimal calcularMontoCubierto() => _montoInicial;

  /// Information Expert: rechaza si ya tiene abonos; si no, el saldo queda en
  /// cero y el estado en ANULADO (CUS-20, DA-51).
  void anular() {
    if (_abonos.isNotEmpty) throw const ExcepcionFiadoConAbonos();
    _saldoPendiente = Decimal.zero;
    _estado = EstadoFiado.anulado;
  }

  /// Devuelve el saldo y el estado que tenía, cuando una operación que lo
  /// cambió en memoria no pudo guardarse (rollback de CUS-20). No está en EA.
  void restaurar(Decimal saldoPendiente, EstadoFiado estado) {
    _saldoPendiente = saldoPendiente;
    _estado = estado;
  }
}
