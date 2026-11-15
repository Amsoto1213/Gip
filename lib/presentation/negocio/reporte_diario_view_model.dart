import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_caja/generar_reporte_diario_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Reporte del día (CUS-10). Llama solo a
/// [GenerarReporteDiarioCoordinator]. El reporte no se guarda: se genera cada
/// vez que se abre o se cambia el día (DA-40).
class ReporteDiarioViewModel extends ChangeNotifier {
  ReporteDiarioViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _fecha = _hoy();
  }

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  static const _mensajeFalla =
      'No se pudo generar el reporte. Intente de nuevo';

  final GenerarReporteDiarioCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  final DateTime Function() _reloj;

  late DateTime _fecha;
  ReporteDiario? _reporte;
  String? _error;
  bool _cargando = false;

  /// Cada consulta lleva un número; solo la última pinta su resultado.
  int _consulta = 0;

  DateTime _hoy() {
    final ahora = _reloj();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  /// Día del reporte, a las 00:00 locales.
  DateTime get fecha => _fecha;

  bool get esHoy => _fecha == _hoy();

  /// No se pueden pedir días que todavía no llegan.
  bool get puedeAvanzar => _fecha.isBefore(_hoy());

  bool get cargando => _cargando;

  /// Mensaje para el tendero si el reporte no se pudo generar.
  String? get error => _error;

  ReporteDiario? get reporte => _reporte;

  /// Verdadero si el día no tiene ventas, abonos, entradas ni egresos de caja.
  bool get sinMovimiento {
    final r = _reporte;
    if (r == null) return false;
    return [
      r.getTotalVentas(),
      r.getAbonosRecibidos(),
      r.getTotalEntradas(),
      r.getGastosNegocio(),
      r.getRetirosPersonales(),
    ].every((v) => v == Decimal.zero);
  }

  Future<void> irDiaAnterior() =>
      elegirFecha(DateTime(_fecha.year, _fecha.month, _fecha.day - 1));

  Future<void> irDiaSiguiente() {
    if (!puedeAvanzar) return Future.value();
    return elegirFecha(DateTime(_fecha.year, _fecha.month, _fecha.day + 1));
  }

  /// Cambia el día y genera el reporte; un día futuro se lleva a hoy.
  Future<void> elegirFecha(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final hoy = _hoy();
    _fecha = dia.isAfter(hoy) ? hoy : dia;
    return cargar();
  }

  /// Genera el reporte del día elegido.
  Future<void> cargar() async {
    final consulta = ++_consulta;
    _cargando = true;
    _error = null;
    notifyListeners();
    ReporteDiario? reporte;
    String? error;
    try {
      reporte = await _coordinador.generarReporte(
        _usuarioActivo.tienda,
        _fecha,
        _usuarioActivo.usuario,
      );
    } on ExcepcionSoloPropietario {
      error = mensajeSoloPropietario;
    } on ExcepcionNegocio catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = _mensajeFalla;
    }
    if (consulta != _consulta) return;
    _reporte = reporte;
    _error = error;
    _cargando = false;
    notifyListeners();
  }
}
