import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';

/// Protected Variations: guarda en el dispositivo el usuario activo con su
/// tienda y su rol, para entrar sin internet con la sesión guardada (DI-12).
/// Hoy lo implementa la Data Layer con shared_preferences; se puede pasar a
/// drift sin tocar las demás capas.
abstract interface class ISesionLocal {
  Future<void> guardar(UsuarioActivo usuarioActivo);

  /// El usuario activo guardado, o null si no hay.
  Future<UsuarioActivo?> leer();

  Future<void> borrar();
}
