import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado del formulario de abono (CUS-08, mockups `mAbono` y `wClientes`).
/// Llama solo a [RegistrarAbonoCoordinator]: el cliente y sus fiados ya los
/// leyó CUS-19. Los errores de monto se detectan antes de llamar, así el
/// [Fiado] no se toca; si falla el guardado, [debeRecargar] avisa que el
/// fiado en memoria quedó con el saldo ya rebajado y hay que volver a leerlo
/// de la base (DI-27).
class AbonoViewModel extends ChangeNotifier {
  AbonoViewModel(
    this._coordinator,
    this._tienda,
    Cliente cliente, {
    Fiado? fiado,
  }) : fiados = (cliente.obtenerFiadosPendientes().toList()
         ..sort((a, b) => a.getFechaInicio().compareTo(b.getFechaInicio()))) {
    final elegido = fiado ?? (fiados.length == 1 ? fiados.single : null);
    if (elegido != null) _elegirSinAvisar(elegido);
  }

  /// Mensajes de la pantalla que no están en el diagrama (DI-27).
  static const mensajeErrorRegistrar =
      'No se pudo registrar el abono. Intente de nuevo';
  static const mensajeElegirFiado = 'Elija a cuál fiado abona';

  final RegistrarAbonoCoordinator _coordinator;
  final Tienda _tienda;

  /// Fiados pendientes del cliente, del más antiguo al más reciente.
  final List<Fiado> fiados;

  Fiado? _fiado;
  String _montoTexto = '';
  MedioPago _medio = MedioPago.efectivo;
  String _referencia = '';
  bool _registrando = false;
  bool _intento = false;
  String? _error;
  bool _debeRecargar = false;
  Decimal? _saldoNuevo;

  Fiado? get fiado => _fiado;
  MedioPago get medio => _medio;
  bool get registrando => _registrando;

  /// Texto con que debe verse el campo del monto: al elegir un fiado se
  /// sugiere su saldo.
  String get montoTexto => _montoTexto;

  /// Monto escrito, o null si está vacío o no es un número.
  Decimal? get monto => leerPesos(_montoTexto);

  /// "El abono debe ser mayor que cero y no puede superar el saldo
  /// pendiente" mientras el monto escrito no sirva, o null.
  String? get errorMonto {
    final fiado = _fiado;
    if (fiado == null) return null;
    final texto = _montoTexto.trim();
    if (texto.isEmpty && !_intento) return null;
    return _montoValido(fiado) ? null : _mensajeMonto;
  }

  /// "Elija a cuál fiado abona" si se intentó abonar sin elegir, o null.
  String? get errorFiado =>
      _intento && _fiado == null ? mensajeElegirFiado : null;

  /// Error al guardar ("No se pudo registrar el abono…" o el de la caja).
  String? get error => _error;

  /// Verdadero si el guardado falló y el fiado en memoria ya no es de fiar:
  /// quien muestre el formulario debe volver a leer al cliente de la base.
  bool get debeRecargar => _debeRecargar;

  /// Nuevo saldo del fiado tras un abono registrado.
  Decimal? get saldoNuevo => _saldoNuevo;

  /// Verdadero si con este monto el fiado queda saldado (RN-05).
  bool get quedaSaldado {
    final fiado = _fiado;
    return fiado != null &&
        _montoValido(fiado) &&
        monto == fiado.getSaldoPendiente();
  }

  /// Monto válido para el botón "Registrar abono de $ N", o null.
  Decimal? get montoParaBoton {
    final fiado = _fiado;
    return fiado != null && _montoValido(fiado) ? monto : null;
  }

  static final String _mensajeMonto =
      const ExcepcionMontoAbonoNoValido().mensaje;

  bool _montoValido(Fiado fiado) {
    final m = monto;
    return m != null && m > Decimal.zero && m <= fiado.getSaldoPendiente();
  }

  void _elegirSinAvisar(Fiado fiado) {
    _fiado = fiado;
    _montoTexto = mostrarPrecio(fiado.getSaldoPendiente());
  }

  /// Elige a cuál fiado abona y sugiere su saldo como monto.
  void elegirFiado(Fiado fiado) {
    _elegirSinAvisar(fiado);
    _error = null;
    notifyListeners();
  }

  void cambiarMonto(String texto) {
    _montoTexto = texto;
    _error = null;
    notifyListeners();
  }

  void elegirMedio(MedioPago medio) {
    _medio = medio;
    notifyListeners();
  }

  void cambiarReferencia(String texto) {
    _referencia = texto;
  }

  /// Registra el abono. Devuelve verdadero si quedó guardado; si no, deja el
  /// motivo en [errorFiado], [errorMonto] o [error].
  Future<bool> registrar() async {
    if (_registrando) return false;
    _intento = true;
    _error = null;
    final fiado = _fiado;
    if (fiado == null || !_montoValido(fiado)) {
      notifyListeners();
      return false;
    }
    _registrando = true;
    notifyListeners();
    try {
      await _coordinator.registrarAbono(
        _tienda,
        fiado,
        monto!,
        _medio,
        _medio == MedioPago.nequi ? _referencia : null,
      );
      _saldoNuevo = fiado.getSaldoPendiente();
      return true;
    } catch (e) {
      _debeRecargar = true;
      _error = e is ExcepcionNegocio ? e.mensaje : mensajeErrorRegistrar;
      return false;
    } finally {
      _registrando = false;
      notifyListeners();
    }
  }
}
