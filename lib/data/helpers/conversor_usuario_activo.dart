import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';

/// Convierte la fila de `usuarios` con su tienda unida
/// (`select id, nombre, cedula, rol, activo, tiendas(...)`) en [UsuarioActivo],
/// y al revés. Lo usan AutenticacionSupabase y SesionLocalPreferencias, que
/// guarda la misma forma en el dispositivo.
class ConversorUsuarioActivo {
  const ConversorUsuarioActivo._();

  static const columnas =
      'id, nombre, cedula, rol, activo, tiendas(id, codigo, nombre, direccion)';

  static UsuarioActivo desdeFila(Map<String, dynamic> fila) {
    final t = fila['tiendas'] as Map<String, dynamic>;
    final id = fila['id'] as String;
    final nombre = fila['nombre'] as String;
    final cedula = fila['cedula'] as String;
    final activo = fila['activo'] as bool? ?? true;
    final usuario = switch (fila['rol']) {
      'ADMINISTRADOR' => Administrador(id, nombre, cedula, activo: activo),
      'EMPLEADO' => Empleado(id, nombre, cedula, activo: activo),
      final rol => throw FormatException('Rol desconocido: $rol'),
    };
    final tienda = Tienda(
      t['id'] as String,
      t['codigo'] as String,
      t['nombre'] as String,
      t['direccion'] as String? ?? '',
    );
    return (usuario: usuario, tienda: tienda);
  }

  static Map<String, dynamic> aFila(UsuarioActivo activo) {
    final u = activo.usuario;
    final t = activo.tienda;
    return {
      'id': u.getId(),
      'nombre': u.getNombre(),
      'cedula': u.getCedula(),
      'rol': u is Administrador ? 'ADMINISTRADOR' : 'EMPLEADO',
      'activo': u.isActivo(),
      'tiendas': {
        'id': t.getId(),
        'codigo': t.getCodigo(),
        'nombre': t.getNombre(),
        'direccion': t.getDireccion(),
      },
    };
  }
}
