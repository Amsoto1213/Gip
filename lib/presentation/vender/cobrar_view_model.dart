import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/vender/fiar_view_model.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Medio que el tendero está llenando en la pantalla Cobrar.
enum MedioCobro { efectivo, nequi, fiado }

/// Estado de la pantalla Cobrar (CUS-02, mockup `Cobro`). Llama solo a
/// [RegistrarVentaCoordinator].
///
/// Conserva el [PagoContado], el [PagoNequi] y el [Fiado] (CUS-07) hasta
/// confirmar; antes no se guarda nada (DA-57). El efectivo cubre lo que no
/// cubren Nequi y el fiado: si alguno cambia, vuelve a pedir el pago de
/// contado con el mismo efectivo recibido (DI-21, DI-26).
class CobrarViewModel extends ChangeNotifier {
  CobrarViewModel(
    this._coordinator,
    this._tienda,
    List<LineaVenta> lineas,
    this.total,
  ) : _lineas = List.unmodifiable(lineas);

  /// Mensaje del diagrama si falla al guardar (paso 80).
  static const mensajeErrorConfirmar =
      'No se pudo registrar la venta. Intente de nuevo';

  /// Billetes para las sugerencias de efectivo recibido.
  static final _billetes = [
    5000,
    10000,
    20000,
    50000,
    100000,
  ].map(Decimal.fromInt);

  final RegistrarVentaCoordinator _coordinator;
  final Tienda _tienda;
  final List<LineaVenta> _lineas;

  /// Total de la venta que calculó Vender (obtenerTotal).
  final Decimal total;

  MedioCobro _medio = MedioCobro.efectivo;
  Decimal? _efectivoRecibido;
  PagoContado? _contado;
  PagoNequi? _nequi;
  Fiado? _fiado;
  String? _errorEfectivo;
  String? _errorNequi;
  String? _error;
  bool _confirmando = false;

  int get cantidadProductos => _lineas.length;
  MedioCobro get medio => _medio;
  PagoContado? get contado => _contado;
  PagoNequi? get nequi => _nequi;
  Fiado? get fiado => _fiado;
  Decimal? get efectivoRecibido => _efectivoRecibido;

  /// Error del campo de efectivo ("El monto recibido no alcanza"), o null.
  String? get errorEfectivo => _errorEfectivo;

  /// Error del campo de Nequi, o null.
  String? get errorNequi => _errorNequi;

  /// Error al confirmar, o null.
  String? get error => _error;

  bool get confirmando => _confirmando;

  Decimal get _montoNequi => _nequi?.getMonto() ?? Decimal.zero;

  /// Lo que debe cubrir el efectivo: el total menos lo pagado por Nequi y lo
  /// fiado.
  Decimal get efectivoACubrir =>
      total - _montoNequi - (_fiado?.getMontoInicial() ?? Decimal.zero);

  /// Lo que falta por cubrir con las formas de pago actuales. Negativo si
  /// entre todas pasan el total.
  Decimal get faltante =>
      total -
      formasPago.fold(Decimal.zero, (s, f) => s + f.calcularMontoCubierto());

  bool get pagoCompleto => faltante == Decimal.zero;

  /// Formas de pago que se entregan al confirmar.
  List<FormaPago> get formasPago =>
      [_contado, _nequi, _fiado].nonNulls.toList();

  /// Lo que se le pasa a Fiar: lo que ya cubren el efectivo recibido (aunque
  /// no alcance) y Nequi, y lo que falta, que es lo que se sugiere fiar.
  DatosFiar get datosFiar {
    final restoNequi = total - _montoNequi;
    final recibido = _efectivoRecibido ?? Decimal.zero;
    final efectivo = restoNequi <= Decimal.zero || recibido <= Decimal.zero
        ? Decimal.zero
        : (recibido < restoNequi ? recibido : restoNequi);
    final yaPago = _montoNequi + efectivo;
    final falta = total - yaPago;
    final medios = [
      if (efectivo > Decimal.zero) 'efectivo',
      if (_montoNequi > Decimal.zero) 'Nequi',
    ];
    return (
      total: total,
      yaPago: yaPago,
      detallePagado: medios.isEmpty ? 'nada aún' : medios.join(' y '),
      falta: falta > Decimal.zero ? falta : Decimal.zero,
    );
  }

  /// Sugerencias de efectivo recibido: el monto justo y los tres primeros
  /// redondeos a billetes que lo superan (mockup `Cobro`).
  List<Decimal> get sugerenciasEfectivo {
    final aCubrir = efectivoACubrir;
    if (aCubrir <= Decimal.zero) return const [];
    final redondeos = {
      for (final b in _billetes) (aCubrir / b).ceil().toDecimal() * b,
    }.where((v) => v > aCubrir).toList()..sort();
    return [aCubrir, ...redondeos.take(3)];
  }

  void elegirMedio(MedioCobro medio) {
    _medio = medio;
    notifyListeners();
  }

  /// Efectivo recibido como lo escribe el tendero ("20.000"). Pide el pago de
  /// contado al coordinador (pasos 29 a 40).
  void cambiarEfectivo(String texto) {
    _efectivoRecibido = leerPesos(texto);
    _error = null;
    _recalcularContado();
    notifyListeners();
  }

  /// Chip de sugerencia ("Justo", "20 mil").
  void elegirEfectivo(Decimal valor) {
    _efectivoRecibido = valor;
    _error = null;
    _recalcularContado();
    notifyListeners();
  }

  /// Monto y referencia de Nequi (pasos 41 a 46). Con el monto vacío quita el
  /// pago. Recalcula el contado, que cubre el resto.
  void cambiarNequi(String montoTexto, String referencia) {
    _error = null;
    _errorNequi = null;
    final monto = leerPesos(montoTexto);
    if (montoTexto.trim().isEmpty) {
      _nequi = null;
    } else if (monto == null) {
      _nequi = null;
      _errorNequi = 'Escriba el monto pagado por Nequi';
    } else {
      try {
        _nequi = _coordinator.pagarConNequi(monto, referencia);
      } on ExcepcionNegocio catch (e) {
        _nequi = null;
        _errorNequi = e.mensaje;
      }
    }
    _recalcularContado();
    notifyListeners();
  }

  /// "×" del pago en efectivo.
  void quitarContado() {
    _efectivoRecibido = null;
    _contado = null;
    _errorEfectivo = null;
    notifyListeners();
  }

  /// Fiado preparado en Fiar (CUS-07): reemplaza al anterior y el efectivo
  /// pasa a cubrir solo lo que no se fía.
  void agregarFiado(Fiado fiado) {
    _fiado = fiado;
    _error = null;
    _recalcularContado();
    notifyListeners();
  }

  /// "×" del fiado.
  void quitarFiado() {
    _fiado = null;
    _error = null;
    _recalcularContado();
    notifyListeners();
  }

  /// "×" del pago por Nequi.
  void quitarNequi() {
    _nequi = null;
    _errorNequi = null;
    _recalcularContado();
    notifyListeners();
  }

  void _recalcularContado() {
    _errorEfectivo = null;
    final recibido = _efectivoRecibido;
    if (recibido == null || efectivoACubrir <= Decimal.zero) {
      _contado = null;
      return;
    }
    try {
      _contado = _coordinator.pagarDeContado(efectivoACubrir, recibido);
    } on ExcepcionNegocio catch (e) {
      _contado = null;
      _errorEfectivo = e.mensaje;
    }
  }

  /// confirmarVenta (pasos 47 a 80). Devuelve verdadero si quedó registrada,
  /// para que la vista vuelva a Vender. Las formas de pago no válidas
  /// muestran su mensaje; cualquier otro error, [mensajeErrorConfirmar].
  Future<bool> confirmar() async {
    if (_confirmando) return false;
    _confirmando = true;
    _error = null;
    notifyListeners();
    try {
      await _coordinator.confirmarVenta(_tienda, _lineas, formasPago);
      return true;
    } on ExcepcionFormasPagoNoValidas catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = mensajeErrorConfirmar;
      return false;
    } finally {
      _confirmando = false;
      notifyListeners();
    }
  }
}
