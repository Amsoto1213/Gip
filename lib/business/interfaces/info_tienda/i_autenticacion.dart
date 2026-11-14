import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';

/// Protected Variations: inicio de sesión con correo y contraseña (DI-05).
/// La Data Layer lo implementa con Supabase Auth; la Business Layer no sabe cómo.
abstract interface class IAutenticacion {
  /// Valida las credenciales y devuelve el usuario con su tienda y su rol
  /// (la fila de `usuarios` con ese correo). Lanza
  /// [ExcepcionCredencialesInvalidas], [ExcepcionSinConexion] o
  /// [ExcepcionUsuarioNoRegistrado].
  Future<UsuarioActivo> iniciarSesion(String correo, String clave);

  /// Verdadero si el dispositivo guarda una sesión de un inicio anterior.
  /// No usa la red.
  bool haySesionGuardada();

  /// Cierra la sesión en este dispositivo.
  Future<void> cerrarSesion();
}
