import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla de inicio de sesión (DI-05). Llama solo a
/// [IniciarSesionCoordinator].
class IniciarSesionViewModel extends ChangeNotifier {
  IniciarSesionViewModel(this._coordinator);

  final IniciarSesionCoordinator _coordinator;

  bool _verificandoSesion = true;
  bool _enviando = false;
  String? _error;
  UsuarioActivo? _usuarioActivo;

  /// Verdadero mientras se revisa si hay una sesión guardada al abrir la app.
  bool get verificandoSesion => _verificandoSesion;
  bool get enviando => _enviando;
  String? get error => _error;
  UsuarioActivo? get usuarioActivo => _usuarioActivo;

  /// Si el dispositivo guarda una sesión, entra directo (también sin internet).
  Future<void> verificarSesionGuardada() async {
    try {
      _usuarioActivo = await _coordinator.sesionGuardada();
    } finally {
      _verificandoSesion = false;
      notifyListeners();
    }
  }

  Future<void> iniciarSesion(String correo, String clave) async {
    if (_enviando) return;
    _enviando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActivo = await _coordinator.iniciarSesion(correo, clave);
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo iniciar sesión. Inténtalo de nuevo';
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }
}
