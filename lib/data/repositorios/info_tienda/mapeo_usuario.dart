import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conversión entre las filas de `usuarios` (Supabase) y [Usuario] (DI-42).
abstract final class MapeoUsuario {
  /// Columnas que lee la app. `correo` no está: lo maneja la cuenta de acceso,
  /// fuera de la Business Layer (DA-67).
  static const columnas = 'id, nombre, cedula, rol, activo';

  static const rolAdministrador = 'ADMINISTRADOR';
  static const rolEmpleado = 'EMPLEADO';

  static Usuario aEntidad(Map<String, dynamic> fila) {
    final id = fila['id'] as String;
    final nombre = fila['nombre'] as String;
    final cedula = fila['cedula'] as String;
    final activo = fila['activo'] as bool? ?? true;
    return switch (fila['rol']) {
      rolAdministrador => Administrador(id, nombre, cedula, activo: activo),
      rolEmpleado => Empleado(id, nombre, cedula, activo: activo),
      final rol => throw FormatException('Rol desconocido: $rol'),
    };
  }

  /// Fila para `upsert`. No lleva `correo`: al actualizar un usuario que ya
  /// tiene correo no se lo borra, y al crear queda vacío hasta que se le crea
  /// la cuenta de acceso. `actualizado_en` va en UTC (DA-48).
  static Map<String, dynamic> aFila(
    Tienda tienda,
    Usuario usuario, {
    DateTime? ahora,
  }) => {
    'id': usuario.getId(),
    'tienda_id': tienda.getId(),
    'nombre': usuario.getNombre(),
    'cedula': usuario.getCedula(),
    'rol': usuario is Administrador ? rolAdministrador : rolEmpleado,
    'activo': usuario.isActivo(),
    'actualizado_en': (ahora ?? DateTime.now()).toUtc().toIso8601String(),
  };

  /// Lo que ve el tendero cuando falla una llamada al servidor: si el servidor
  /// respondió con un error de datos (por ejemplo, la cédula ya existe en la
  /// tienda, `unique (tienda_id, cedula)`, código 23505) son datos no válidos;
  /// cualquier otra falla es que no hay red.
  static Object traducirError(Object error) => switch (error) {
    PostgrestException(code: '23505') => const ExcepcionDatosUsuarioNoValidos(),
    PostgrestException() => error,
    _ => const ExcepcionSinConexionUsuarios(),
  };
}
