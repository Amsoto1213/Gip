/// Valores de la gestión de usuarios (CUS-15).
abstract final class ConfiguracionUsuarios {
  /// Largo mínimo de la contraseña de un empleado: el que pide Supabase
  /// (`supabase/config.toml`, `minimum_password_length`). Si se cambia allá,
  /// se cambia aquí (DI-43).
  static const int largoMinimoClave = 6;
}
