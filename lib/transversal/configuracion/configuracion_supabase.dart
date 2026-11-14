/// Configuración de Supabase inyectada al compilar con
/// `--dart-define-from-file=.env.json` (DI-04). El archivo cambia en cada equipo
/// (Supabase local o el de pruebas en la nube) y no se sube a git.
class ConfiguracionSupabase {
  const ConfiguracionSupabase({required this.url, required this.anonKey});

  /// Lee los valores definidos al compilar.
  const ConfiguracionSupabase.desdeEntorno()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  final String url;
  final String anonKey;

  /// Falla con un mensaje claro si la app se compiló sin `.env.json`.
  void validar() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Falta la configuración de Supabase (SUPABASE_URL y SUPABASE_ANON_KEY). '
        'Ejecuta la app con --dart-define-from-file=.env.json',
      );
    }
  }
}
