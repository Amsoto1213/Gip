import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conversión entre las filas de `usuarios` (Supabase) y [Usuario] (DI-42).
abstract final class MapeoUsuario {
  /// Columnas que lee la app. `correo` es con el que el usuario inicia sesión
  /// (DI-43).
  static const columnas = 'id, nombre, cedula, rol, activo, correo';

  static const rolAdministrador = 'ADMINISTRADOR';
  static const rolEmpleado = 'EMPLEADO';

  static Usuario aEntidad(Map<String, dynamic> fila) {
    final id = fila['id'] as String;
    final nombre = fila['nombre'] as String;
    final cedula = fila['cedula'] as String;
    final activo = fila['activo'] as bool? ?? true;
    final correo = fila['correo'] as String?;
    return switch (fila['rol']) {
      rolAdministrador => Administrador(
        id,
        nombre,
        cedula,
        correo: correo,
        activo: activo,
      ),
      rolEmpleado => Empleado(
        id,
        nombre,
        cedula,
        correo: correo,
        activo: activo,
      ),
      final rol => throw FormatException('Rol desconocido: $rol'),
    };
  }

  /// Fila para `upsert`. Lleva `correo` solo si el usuario lo tiene: así, al
  /// actualizar uno que se leyó sin correo no se borra el que hay en el
  /// servidor. `actualizado_en` va en UTC (DA-48).
  static Map<String, dynamic> aFila(
    Tienda tienda,
    Usuario usuario, {
    DateTime? ahora,
  }) => {
    'id': usuario.getId(),
    'tienda_id': tienda.getId(),
    'nombre': usuario.getNombre(),
    'cedula': usuario.getCedula(),
    if (usuario.getCorreo() != null) 'correo': usuario.getCorreo(),
    'rol': usuario is Administrador ? rolAdministrador : rolEmpleado,
    'activo': usuario.isActivo(),
    'actualizado_en': (ahora ?? DateTime.now()).toUtc().toIso8601String(),
  };

  /// Lo que ve el tendero cuando falla una llamada al servidor. Una fila
  /// repetida (código 23505) es el correo ya registrado
  /// (`usuarios_correo_key`) o la cédula ya existente en la tienda
  /// (`unique (tienda_id, cedula)`: datos no válidos). Cualquier otra falla del
  /// servidor llega tal cual; sin respuesta, es que no hay red.
  static Object traducirError(Object error) => switch (error) {
    PostgrestException(code: '23505') when _habla(error, 'correo') =>
      const ExcepcionCorreoYaRegistrado(),
    PostgrestException(code: '23505') => const ExcepcionDatosUsuarioNoValidos(),
    PostgrestException() => error,
    _ => const ExcepcionSinConexionUsuarios(),
  };

  static bool _habla(PostgrestException e, String texto) =>
      '${e.message} ${e.details ?? ''}'.toLowerCase().contains(texto);
}
