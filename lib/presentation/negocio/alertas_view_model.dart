import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Pestañas de la pantalla Alertas de surtido.
enum PestanaAlertas { porSurtir, ventasPerdidas }

/// Estado de la pantalla Alertas de surtido (CUS-05). Llama solo a
/// [ConsultarAlertasCoordinator]: las alertas del día ya calculadas (CUS-24) y
/// las ventas perdidas de los últimos 30 días, que también dan "Se fueron sin
/// comprar" de cada alerta (DI-25).
class AlertasViewModel extends ChangeNotifier {
  AlertasViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  /// Mensaje del diagrama cuando no es el propietario (paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  /// Mensaje del diagrama cuando no hay alertas del día (paso 14).
  static const mensajeSinAlertas = 'No hay productos por agotarse';

  static const _mensajeFalla =
      'No se pudieron cargar las alertas. Intente de nuevo';

  /// Días hacia atrás de las ventas perdidas que se muestran.
  static const diasVentasPerdidas = 30;

  final ConsultarAlertasCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  final DateTime Function() _reloj;

  bool _cargando = false;
  String? _error;
  List<AlertaReabastecimiento> _alertas = const [];
  List<VentaPerdida> _ventasPerdidas = const [];
  Map<String, int> _perdidasPorProducto = const {};
  PestanaAlertas _pestana = PestanaAlertas.porSurtir;

  bool get cargando => _cargando;

  /// Mensaje para el tendero si la consulta no se pudo hacer.
  String? get error => _error;
  List<AlertaReabastecimiento> get alertas => _alertas;
  List<VentaPerdida> get ventasPerdidas => _ventasPerdidas;
  PestanaAlertas get pestana => _pestana;

  /// Hay alerta con menos de 30 días de historial (para la nota).
  bool get hayProvisionales => _alertas.any((a) => a.isProvisional());

  /// Veces que el producto se pidió agotado en los últimos 30 días.
  int ventasPerdidasDe(String productoId) =>
      _perdidasPorProducto[productoId] ?? 0;

  void elegirPestana(PestanaAlertas pestana) {
    if (pestana == _pestana) return;
    _pestana = pestana;
    notifyListeners();
  }

  /// Consulta las alertas de hoy y las ventas perdidas de los últimos 30 días
  /// (de hace 30 días a hoy, incluido).
  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    final ahora = _reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final tienda = _usuarioActivo.tienda;
    final usuario = _usuarioActivo.usuario;
    try {
      final alertas = await _coordinador.consultarAlertas(tienda, hoy, usuario);
      final perdidas = await _coordinador.consultarVentasPerdidas(
        tienda,
        DateTime(hoy.year, hoy.month, hoy.day - diasVentasPerdidas),
        DateTime(hoy.year, hoy.month, hoy.day + 1),
        usuario,
      );
      _alertas = alertas;
      _ventasPerdidas = perdidas;
      final conteo = <String, int>{};
      for (final v in perdidas) {
        conteo.update(v.getProductoId(), (n) => n + 1, ifAbsent: () => 1);
      }
      _perdidasPorProducto = conteo;
    } on ExcepcionSoloPropietario {
      _error = mensajeSoloPropietario;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFalla;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
