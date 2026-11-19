import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/exportar_datos_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_exportacion.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Exportar datos (CUS-16). Llama solo a
/// [ExportarDatosCoordinator]. Los dos días son días locales y los dos se
/// incluyen: al coordinador le llega `hasta` como el día siguiente al último
/// (`[desde, hasta)`, DI-28).
class ExportarViewModel extends ChangeNotifier {
  ExportarViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) {
    final ahora = (reloj ?? DateTime.now)();
    _hoy = DateTime(ahora.year, ahora.month, ahora.day);
    _desde = DateTime(_hoy.year, _hoy.month);
    _ultimoDia = _hoy;
  }

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  /// Lo que ve el tendero cuando el periodo no es válido (CUS-16, paso 8).
  static const mensajePeriodo =
      'La fecha inicial no puede ser posterior a la final';

  static const _mensajeFalla = 'No se pudo exportar. Intente de nuevo';

  final ExportarDatosCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  late final DateTime _hoy;

  late DateTime _desde;
  late DateTime _ultimoDia;
  FormatoExportacion _formato = FormatoExportacion.excel;
  bool _exportando = false;
  String? _error;
  String? _mensajeListo;

  /// Hoy, en día local; es lo último que se puede elegir.
  DateTime get hoy => _hoy;

  /// Primer día del periodo (incluido). Empieza en el día 1 del mes actual.
  DateTime get desde => _desde;

  /// Último día del periodo (incluido). Empieza en hoy.
  DateTime get ultimoDia => _ultimoDia;

  FormatoExportacion get formato => _formato;
  bool get exportando => _exportando;

  /// Mensaje para el tendero si no se pudo exportar.
  String? get error => _error;

  /// "Datos exportados: nombre", cuando el archivo ya se entregó (CUS-16,
  /// paso 20). En CSV dice que son tres archivos.
  String? get mensajeListo => _mensajeListo;

  /// Aviso si el último día es anterior al primero; se ve al elegir las
  /// fechas, antes de exportar.
  String? get errorPeriodo =>
      _ultimoDia.isBefore(_desde) ? mensajePeriodo : null;

  bool get puedeExportar => !_exportando && errorPeriodo == null;

  void elegirDesde(DateTime dia) {
    _desde = DateTime(dia.year, dia.month, dia.day);
    _cambio();
  }

  void elegirHasta(DateTime dia) {
    _ultimoDia = DateTime(dia.year, dia.month, dia.day);
    _cambio();
  }

  void elegirFormato(FormatoExportacion formato) {
    _formato = formato;
    _cambio();
  }

  /// Un cambio en el formulario deja sin efecto el resultado anterior.
  void _cambio() {
    _error = null;
    _mensajeListo = null;
    notifyListeners();
  }

  /// Exporta los datos del periodo en el formato elegido y entrega el archivo.
  Future<void> exportar() async {
    if (!puedeExportar) return;
    _exportando = true;
    _error = null;
    _mensajeListo = null;
    notifyListeners();
    try {
      final nombre = await _coordinador.exportar(
        _usuarioActivo.tienda,
        _desde,
        DateTime(_ultimoDia.year, _ultimoDia.month, _ultimoDia.day + 1),
        _formato,
        _usuarioActivo.usuario,
      );
      _mensajeListo = _formato == FormatoExportacion.csv
          ? 'Datos exportados: $nombre (3 archivos CSV)'
          : 'Datos exportados: $nombre';
    } on ExcepcionSoloPropietario {
      _error = mensajeSoloPropietario;
    } on ExcepcionPeriodoNoValido {
      _error = mensajePeriodo;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFalla;
    } finally {
      _exportando = false;
      notifyListeners();
    }
  }
}
