import 'package:flutter/foundation.dart';
import 'package:gip/transversal/configuracion/configuracion_usuarios.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Qué errores de Supabase Auth significan algo para el tendero al crear la
/// cuenta de un empleado (DI-43). Solo funciones puras: se prueban sin red.
abstract final class MapeoCuentaAcceso {
  /// Verdadero si el error dice que ya hay una cuenta con ese correo.
  static bool cuentaYaExiste(AuthException e) =>
      e.code == 'user_already_exists' ||
      e.code == 'email_exists' ||
      (e.statusCode == '422' &&
          e.message.toLowerCase().contains('already registered'));

  /// Verdadero si el error dice que las credenciales no coinciden (la cuenta
  /// existe, pero con otra contraseña).
  static bool credencialesNoCoinciden(AuthException e) =>
      e.code == 'invalid_credentials' ||
      e.message.toLowerCase().contains('invalid login credentials');

  /// Lo que ve el tendero: un error de negocio se deja tal cual; sin respuesta
  /// del servidor, "Necesitas internet…"; lo demás, que no se pudo crear la
  /// cuenta.
  static Object traducirError(Object error) => switch (error) {
    ExcepcionNegocio() => error,
    AuthApiException(code: 'weak_password') => const ExcepcionClaveNoValida(
      ConfiguracionUsuarios.largoMinimoClave,
    ),
    AuthApiException() when cuentaYaExiste(error as AuthException) =>
      const ExcepcionCorreoYaRegistrado(),
    AuthRetryableFetchException() => _anotar(
      'Crear cuenta: Supabase Auth no respondió (red o error 5xx)',
      error,
      const ExcepcionSinConexionUsuarios(),
    ),
    AuthException() => _anotar(
      'Crear cuenta: Supabase Auth la rechazó',
      error,
      const ExcepcionCuentaNoCreada(),
    ),
    _ => _anotar(
      'Crear cuenta: falla que no es de Supabase Auth',
      error,
      const ExcepcionSinConexionUsuarios(),
    ),
  };

  /// Deja la causa real en el registro (`adb logcat -s flutter`, o la consola de
  /// `flutter run`): todos estos casos terminan en un mensaje corto para el
  /// tendero y, sin esto, no se sabe cuál fue.
  static Object _anotar(String contexto, Object causa, Object resultado) {
    final detalle = causa is AuthException
        ? 'código=${causa.code} estado=${causa.statusCode} mensaje=${causa.message}'
        : '$causa';
    debugPrint('$contexto → ${causa.runtimeType}: $detalle');
    return resultado;
  }
}
