import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tarjeta_diferencia.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Cierre de caja (CUS-14). Llama solo a
/// [RegistrarCierreCajaCoordinator].
///
/// Muestra el saldo esperado de hoy, deja escribir el efectivo contado con una
/// vista previa de la diferencia y cierra la caja. La vista previa es solo una
/// resta para mostrar: la diferencia que cuenta la calcula `Caja.cerrar`
/// (DI-37).
class CierreCajaViewModel extends ChangeNotifier {
  CierreCajaViewModel(this._coordinador, this._usuarioActivo);

  /// Mensaje cuando el efectivo escrito no es un número o es negativo. No está
  /// en el diagrama (DI-37).
  static const mensajeEfectivoNoValido = 'Escribe cuánto efectivo contó';

  static const _mensajeFalla = 'No se pudo cerrar la caja. Inténtalo de nuevo';
  static const _mensajeFallaSaldo =
      'No se pudo consultar la caja. Inténtalo de nuevo';

  final RegistrarCierreCajaCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;

  Decimal? _saldoEsperado;
  Decimal? _efectivo;
  Decimal? _diferenciaFinal;
  bool _cargando = false;
  bool _cerrando = false;
  String? _error;

  /// Lo que debe haber en caja, o null mientras no se ha consultado.
  Decimal? get saldoEsperado => _saldoEsperado;

  /// Efectivo escrito, si es un valor válido.
  Decimal? get efectivoContado => _efectivo;

  bool get cargando => _cargando;
  bool get cerrando => _cerrando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// Diferencia que devolvió el cierre (negativa: faltante), o null si la caja
  /// todavía no se ha cerrado en esta pantalla.
  Decimal? get diferenciaFinal => _diferenciaFinal;

  bool get cerrada => _diferenciaFinal != null;

  /// Diferencia que se vería al cerrar con el efectivo escrito, o null. Solo
  /// para mostrar (DI-37).
  Decimal? get vistaPrevia {
    final efectivo = _efectivo;
    final saldo = _saldoEsperado;
    if (efectivo == null || saldo == null) return null;
    return efectivo - saldo;
  }

  /// Cómo queda una diferencia: negativa es faltante, positiva sobrante y
  /// cero cuadra (DI-37).
  static TonoDiferencia tonoDe(Decimal diferencia) {
    if (diferencia < Decimal.zero) return TonoDiferencia.faltante;
    if (diferencia > Decimal.zero) return TonoDiferencia.sobrante;
    return TonoDiferencia.cuadra;
  }

  /// "Faltan", "Sobran" o "La caja cuadra".
  static String tituloDe(Decimal diferencia) => switch (tonoDe(diferencia)) {
    TonoDiferencia.faltante => 'Faltan',
    TonoDiferencia.sobrante => 'Sobran',
    TonoDiferencia.cuadra => 'La caja cuadra',
  };

  /// Pesos del valor absoluto ("$ 3.500"), o null si cuadra.
  static String? montoDe(Decimal diferencia) => diferencia == Decimal.zero
      ? null
      : '\$ ${mostrarPrecio(diferencia.abs())}';

  /// Consulta lo que debe haber en caja (CUS-14, pasos 2 a 11).
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _saldoEsperado = await _coordinador.consultarSaldoEsperado(
        _usuarioActivo.tienda,
        _usuarioActivo.usuario,
      );
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFallaSaldo;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Recibe lo que escribe el tendero ("315.000"); lo que no es un valor válido
  /// (vacío, no numérico o negativo) deja sin efectivo y sin vista previa.
  void escribirEfectivo(String texto) {
    if (_cerrando || cerrada) return;
    final valor = leerPesos(texto);
    _efectivo = valor != null && valor >= Decimal.zero ? valor : null;
    _error = null;
    notifyListeners();
  }

  /// Cierra la caja con [texto] como efectivo contado (CUS-14, pasos 12 a 28).
  /// Devuelve verdadero si quedó cerrada.
  Future<bool> cerrar(String texto) async {
    if (_cerrando || cerrada) return false;
    escribirEfectivo(texto);
    final efectivo = _efectivo;
    if (efectivo == null) {
      _error = mensajeEfectivoNoValido;
      notifyListeners();
      return false;
    }

    _cerrando = true;
    notifyListeners();
    var cerro = false;
    try {
      _diferenciaFinal = await _coordinador.cerrarCaja(
        _usuarioActivo.tienda,
        efectivo,
        _usuarioActivo.usuario,
      );
      cerro = true;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFalla;
    } finally {
      _cerrando = false;
      notifyListeners();
    }
    return cerro;
  }
}
