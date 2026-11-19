import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_usuario_repositorio.dart';
import 'package:gip/data/repositorios/info_tienda/mapeo_usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [IUsuarioRepositorio] sobre la tabla `usuarios` de Supabase (DI-42): los
/// usuarios viven en el servidor, junto a sus cuentas de acceso, y esta
/// pantalla necesita internet. Toda consulta filtra por `tienda_id`.
class UsuarioRepositorioSupabase implements IUsuarioRepositorio {
  UsuarioRepositorioSupabase(this._cliente);

  final SupabaseClient _cliente;

  static const _tabla = 'usuarios';

  /// Primero el propietario (`rol` es un enum con ADMINISTRADOR antes de
  /// EMPLEADO) y luego los empleados, cada grupo por nombre.
  @override
  Future<List<Usuario>> listar(Tienda tienda) async {
    try {
      final filas = await _cliente
          .from(_tabla)
          .select(MapeoUsuario.columnas)
          .eq('tienda_id', tienda.getId())
          .order('rol')
          .order('nombre');
      return filas.map(MapeoUsuario.aEntidad).toList();
    } catch (e) {
      throw MapeoUsuario.traducirError(e);
    }
  }

  @override
  Future<Usuario?> buscarPorCedula(Tienda tienda, String cedula) async {
    try {
      final filas = await _cliente
          .from(_tabla)
          .select(MapeoUsuario.columnas)
          .eq('tienda_id', tienda.getId())
          .eq('cedula', cedula)
          .limit(1);
      return filas.isEmpty ? null : MapeoUsuario.aEntidad(filas.first);
    } catch (e) {
      throw MapeoUsuario.traducirError(e);
    }
  }

  /// Crea o actualiza la fila con ese id. No manda `correo`: no se lo borra a
  /// quien ya lo tiene (DI-42).
  @override
  Future<void> guardar(Tienda tienda, Usuario usuario) async {
    try {
      await _cliente
          .from(_tabla)
          .upsert(MapeoUsuario.aFila(tienda, usuario), onConflict: 'id');
    } catch (e) {
      throw MapeoUsuario.traducirError(e);
    }
  }
}
