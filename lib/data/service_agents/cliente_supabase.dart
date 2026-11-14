import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicializa supabase_flutter con la configuración de `.env.json` (DI-04).
/// supabase_flutter guarda la sesión en el dispositivo, así que las siguientes
/// veces la app entra sin internet (DI-05). El cliente devuelto se inyecta por
/// constructor en los service agents que lo usan.
class ClienteSupabase {
  ClienteSupabase(this._configuracion);

  final ConfiguracionSupabase _configuracion;

  Future<SupabaseClient> inicializar() async {
    _configuracion.validar();
    final supabase = await Supabase.initialize(
      url: _configuracion.url,
      // `anonKey` está deprecado; la llave anon (JWT o sb_publishable_) se pasa
      // como publishableKey, que la usa igual.
      publishableKey: _configuracion.anonKey,
    );
    return supabase.client;
  }
}
