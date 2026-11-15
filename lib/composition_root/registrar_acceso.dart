import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/data/local/sesion_local_preferencias.dart';
import 'package:gip/data/service_agents/autenticacion_supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coordinador del inicio de sesión y el [ServicioAcceso], que usan los
/// coordinadores de los casos del propietario (CUS-05).
typedef CoordinadoresAcceso = ({
  IniciarSesionCoordinator iniciarSesion,
  ServicioAcceso servicioAcceso,
});

/// Arma el inicio de sesión (DI-05, DI-12) con sus implementaciones concretas.
CoordinadoresAcceso registrarAcceso(SupabaseClient cliente) {
  final servicioAcceso = ServicioAcceso(
    AutenticacionSupabase(cliente),
    SesionLocalPreferencias(SharedPreferencesAsync()),
  );
  return (
    iniciarSesion: IniciarSesionCoordinator(servicioAcceso),
    servicioAcceso: servicioAcceso,
  );
}
