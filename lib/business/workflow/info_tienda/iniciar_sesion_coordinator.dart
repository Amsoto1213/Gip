import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';

/// Controller del inicio de sesión (DI-05): recibe las operaciones desde la
/// presentación y delega en [ServicioAcceso]; no contiene reglas de negocio.
class IniciarSesionCoordinator {
  IniciarSesionCoordinator(this._servicioAcceso);

  final ServicioAcceso _servicioAcceso;

  Future<UsuarioActivo> iniciarSesion(String correo, String clave) =>
      _servicioAcceso.iniciarSesion(correo, clave);

  /// Usuario de la sesión guardada, o null si hay que iniciar sesión.
  Future<UsuarioActivo?> sesionGuardada() => _servicioAcceso.sesionGuardada();

  /// Falso, y la sesión ya quedó cerrada, si el propietario desactivó al
  /// usuario (DI-44); verdadero si sigue activo o no se pudo saber.
  Future<bool> revisarUsuarioActivo(UsuarioActivo activo) =>
      _servicioAcceso.revisarUsuarioActivo(activo);

  /// Cierra la sesión: borra el usuario guardado y la sesión de Auth.
  Future<void> cerrarSesion() => _servicioAcceso.cerrarSesion();
}
