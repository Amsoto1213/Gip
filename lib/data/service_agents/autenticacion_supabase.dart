import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/data/helpers/conversor_usuario_activo.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicio de sesión con Supabase Auth (DI-05): `signInWithPassword` y luego la
/// fila de `usuarios` con ese correo para saber la tienda y el rol.
class AutenticacionSupabase implements IAutenticacion {
  AutenticacionSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<UsuarioActivo> iniciarSesion(String correo, String clave) async {
    try {
      await _cliente.auth.signInWithPassword(email: correo, password: clave);
    } on AuthRetryableFetchException {
      throw const ExcepcionSinConexion();
    } on AuthException {
      throw const ExcepcionCredencialesInvalidas();
    }

    final List<Map<String, dynamic>> filas;
    try {
      filas = await _cliente
          .from('usuarios')
          .select(ConversorUsuarioActivo.columnas)
          .eq('correo', correo)
          .limit(1);
    } catch (_) {
      await cerrarSesion();
      throw const ExcepcionSinConexion();
    }

    if (filas.isEmpty) {
      await cerrarSesion();
      throw const ExcepcionUsuarioNoRegistrado();
    }
    return ConversorUsuarioActivo.desdeFila(filas.first);
  }

  @override
  bool haySesionGuardada() => _cliente.auth.currentSession != null;

  @override
  Future<void> cerrarSesion() async {
    try {
      await _cliente.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Sin red el servidor no se entera, pero la sesión local ya se borró.
    }
  }
}
