import 'package:gip/business/interfaces/info_tienda/i_cuenta_acceso.dart';
import 'package:gip/data/service_agents/mapeo_cuenta_acceso.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Crea la cuenta de acceso de un empleado en Supabase Auth (CUS-15, DI-43).
///
/// Usa un cliente de Supabase **aparte y temporal**, que no comparte la sesión
/// del dispositivo: `signUp` abre sesión con la cuenta nueva y, con el cliente
/// de la app, el propietario quedaría dentro como el empleado. El cliente
/// temporal se cierra y se descarta al terminar.
///
/// Necesita que el proyecto de Supabase permita registros y no pida confirmar
/// el correo (`enable_signup = true` y `enable_confirmations = false`, que es
/// lo que trae `supabase/config.toml`); si pide confirmar, la cuenta no sirve
/// para entrar y se avisa que no se pudo crear. Sin RLS ni políticas, como el
/// resto (DI-05).
class CuentaAccesoSupabase implements ICuentaAcceso {
  /// [crearCliente] arma el cliente temporal; por defecto, uno nuevo con la
  /// URL y la llave de [configuracion] y sin renovar la sesión.
  CuentaAccesoSupabase(
    ConfiguracionSupabase configuracion, {
    SupabaseClient Function()? crearCliente,
  }) : _crearCliente =
           crearCliente ??
           (() => SupabaseClient(
             configuracion.url,
             configuracion.anonKey,
             authOptions: const AuthClientOptions(autoRefreshToken: false),
           ));

  final SupabaseClient Function() _crearCliente;

  @override
  Future<void> crear(String correo, String clave) async {
    final cliente = _crearCliente();
    try {
      await _crearOVerificar(cliente, correo, clave);
    } catch (e) {
      throw MapeoCuentaAcceso.traducirError(e);
    } finally {
      try {
        await cliente.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // El cliente es temporal: no queda nada que cerrar.
      }
      await cliente.dispose();
    }
  }

  Future<void> _crearOVerificar(
    SupabaseClient cliente,
    String correo,
    String clave,
  ) async {
    try {
      final respuesta = await cliente.auth.signUp(
        email: correo,
        password: clave,
      );
      // Sin sesión, Supabase está pidiendo confirmar el correo: la cuenta no
      // serviría para entrar.
      if (respuesta.session == null) throw const ExcepcionCuentaNoCreada();
    } on AuthException catch (e) {
      if (!MapeoCuentaAcceso.cuentaYaExiste(e)) rethrow;
      // Ya hay una cuenta con ese correo. Si es la de un intento anterior de
      // este mismo empleado (misma contraseña), sirve; si no, es de alguien.
      try {
        await cliente.auth.signInWithPassword(email: correo, password: clave);
      } on AuthException catch (e) {
        if (MapeoCuentaAcceso.credencialesNoCoinciden(e)) {
          throw const ExcepcionCorreoYaRegistrado();
        }
        rethrow;
      }
    }
  }
}
