import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';
import 'package:decimal/decimal.dart';

/// Estado de la pantalla Caja: el formulario "Anotar movimiento" (CUS-11) y lo
/// que debe haber en caja con la entrada a "Cerrar caja" (CUS-14).
/// Llama a [RegistrarMovimientoCajaCoordinator] y, para el saldo esperado, a
/// [RegistrarCierreCajaCoordinator]: es la segunda pantalla con dos
/// coordinadores (DI-37). La lista de hoy y "Ventas de hoy" llegan con CUS-20
/// (DI-36).
class CajaViewModel extends ChangeNotifier {
  CajaViewModel(this._coordinador, this._cierre, this._usuarioActivo);

  /// Mensaje del diagrama para un valor cero, negativo o que no es un número
  /// (CUS-11, paso 12).
  static const mensajeValorNoValido = 'El valor debe ser mayor que cero';

  static const _mensajeFalla =
      'No se pudo anotar el movimiento. Inténtalo de nuevo';

  final RegistrarMovimientoCajaCoordinator _coordinador;
  final RegistrarCierreCajaCoordinator _cierre;
  final UsuarioActivo _usuarioActivo;

  TipoMovimientoCaja _tipo = TipoMovimientoCaja.egreso;
  ClasificacionMovimiento _clasificacion = ClasificacionMovimiento.negocio;
  bool _guardando = false;
  String? _error;
  MovimientoCaja? _registrado;
  Decimal? _saldoEsperado;

  /// "Sale dinero" (egreso) o "Entra dinero" (ingreso). Empieza en egreso,
  /// como el mockup.
  TipoMovimientoCaja get tipo => _tipo;

  /// "Del negocio" o "Personal". La clasificación ANULACION no se elige:
  /// solo la usa la anulación de ventas (DA-51).
  ClasificacionMovimiento get clasificacion => _clasificacion;

  bool get guardando => _guardando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// Último movimiento anotado, para confirmarlo en pantalla, o null.
  MovimientoCaja? get registrado => _registrado;

  /// Lo que debe haber en caja hoy, o null si todavía no se consulta o no se
  /// pudo (por ejemplo, un empleado no lo ve).
  Decimal? get saldoEsperado => _saldoEsperado;

  /// Consulta lo que debe haber en caja (CUS-14, pasos 2 a 11). Si falla, la
  /// tarjeta simplemente no se muestra.
  Future<void> cargarSaldo() async {
    try {
      _saldoEsperado = await _cierre.consultarSaldoEsperado(
        _usuarioActivo.tienda,
        _usuarioActivo.usuario,
      );
    } catch (_) {
      _saldoEsperado = null;
    }
    notifyListeners();
  }

  void elegirTipo(TipoMovimientoCaja tipo) {
    if (_guardando) return;
    _tipo = tipo;
    notifyListeners();
  }

  void elegirClasificacion(ClasificacionMovimiento clasificacion) {
    if (_guardando || clasificacion == ClasificacionMovimiento.anulacion) {
      return;
    }
    _clasificacion = clasificacion;
    notifyListeners();
  }

  /// Anota el movimiento (CUS-11, pasos 1 a 28). [valor] llega como lo escribió
  /// el tendero (p. ej. "12.000"). Devuelve verdadero si quedó registrado.
  Future<bool> anotar({
    required String valor,
    required String descripcion,
  }) async {
    if (_guardando) return false;
    _error = null;
    _registrado = null;

    final monto = leerPesos(valor);
    if (monto == null || monto <= Decimal.zero) {
      _error = mensajeValorNoValido;
      notifyListeners();
      return false;
    }

    _guardando = true;
    notifyListeners();
    var registrado = false;
    try {
      _registrado = await _coordinador.registrarMovimiento(
        _usuarioActivo.tienda,
        _tipo,
        _clasificacion,
        monto,
        descripcion.trim(),
        _usuarioActivo.usuario,
      );
      registrado = true;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFalla;
    } finally {
      _guardando = false;
      notifyListeners();
    }
    if (registrado) await cargarSaldo();
    return registrado;
  }
}
