import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';

/// Pure Fabrication: concentra el inicio de sesión (DI-05) y el control de
/// acceso por rol (RNF-12) para que ningún coordinator lo repita (DRY).
class ServicioAcceso {
  ServicioAcceso(this._autenticacion, this._sesionLocal);

  final IAutenticacion _autenticacion;
  final ISesionLocal _sesionLocal;

  /// Valida los datos, inicia sesión y guarda el usuario activo en el
  /// dispositivo para las siguientes entradas sin internet (DI-12).
  Future<UsuarioActivo> iniciarSesion(String correo, String clave) async {
    final correoLimpio = correo.trim().toLowerCase();
    if (correoLimpio.isEmpty) {
      throw const ExcepcionDatoFaltante('Escribe tu correo');
    }
    if (clave.isEmpty) {
      throw const ExcepcionDatoFaltante('Escribe tu contraseña');
    }

    final activo = await _autenticacion.iniciarSesion(correoLimpio, clave);
    if (!activo.usuario.isActivo()) {
      await _autenticacion.cerrarSesion();
      throw const ExcepcionUsuarioInactivo();
    }
    await _sesionLocal.guardar(activo);
    return activo;
  }

  /// Usuario de la sesión guardada en el dispositivo, o null si hay que
  /// iniciar sesión. No usa la red.
  Future<UsuarioActivo?> sesionGuardada() async {
    if (!_autenticacion.haySesionGuardada()) {
      await _sesionLocal.borrar();
      return null;
    }
    return _sesionLocal.leer();
  }

  Future<void> cerrarSesion() async {
    await _sesionLocal.borrar();
    await _autenticacion.cerrarSesion();
  }

  bool _esPropietario(Usuario usuario) => usuario is Administrador;

  /// Rechaza la operación si el usuario no es el propietario (RNF-12).
  void exigirPropietario(Usuario usuario) {
    if (!_esPropietario(usuario)) throw const ExcepcionSoloPropietario();
  }
}
