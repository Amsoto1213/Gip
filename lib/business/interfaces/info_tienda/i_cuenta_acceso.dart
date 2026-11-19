/// Protected Variations: crea la cuenta con la que una persona inicia sesión
/// (correo y contraseña). La Data Layer la implementa con Supabase Auth; la
/// Business Layer no sabe cómo (DA-67, DI-43). Nunca guarda la contraseña.
abstract interface class ICuentaAcceso {
  /// Crea la cuenta con ese [correo] y esa [clave], sin abrir sesión con ella:
  /// la sesión del propietario no cambia. Si ya existe una cuenta con ese
  /// correo y **la misma** contraseña (por ejemplo, un intento anterior que
  /// creó la cuenta pero no alcanzó a guardar al empleado), la da por buena;
  /// si la contraseña es otra, es de alguien más y lanza
  /// `ExcepcionCorreoYaRegistrado`.
  Future<void> crear(String correo, String clave);
}
