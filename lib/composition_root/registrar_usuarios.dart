import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_usuarios.dart';
import 'package:gip/business/workflow/info_tienda/gestionar_usuarios_coordinator.dart';
import 'package:gip/data/repositorios/info_tienda/usuario_repositorio_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Arma la gestión de usuarios de la tienda (CUS-15): [ServicioUsuarios] con el
/// repositorio de Supabase (DI-42).
GestionarUsuariosCoordinator registrarUsuarios(
  SupabaseClient cliente,
  ServicioAcceso servicioAcceso,
) => GestionarUsuariosCoordinator(
  ServicioUsuarios(UsuarioRepositorioSupabase(cliente)),
  servicioAcceso,
);
