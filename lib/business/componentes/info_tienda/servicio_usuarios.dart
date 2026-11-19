import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_usuario_repositorio.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de los usuarios de la tienda (CUS-15): lista, crea
/// empleados y los desactiva. La cuenta de acceso (correo y contraseña) la
/// maneja Supabase Auth, fuera de la Business Layer (DA-67, DI-42).
class ServicioUsuarios {
  ServicioUsuarios(this._usuarios);

  final IUsuarioRepositorio _usuarios;

  /// Llama a usuarios.listar(tienda): activos e inactivos.
  Future<List<Usuario>> listar(Tienda tienda) => _usuarios.listar(tienda);

  /// Creator: valida que el nombre y la cédula no estén vacíos y que
  /// `usuarios.buscarPorCedula(tienda, cedula)` no devuelva a otro usuario
  /// (activo o no); crea el [Empleado] con id nuevo y activo, y lo guarda con
  /// `usuarios.guardar`. Quita los espacios del inicio y del final de los dos
  /// datos. Si algo no cumple lanza [ExcepcionDatosUsuarioNoValidos] sin
  /// guardar nada (CUS-15, pasos 16 a 22; DI-42).
  Future<Empleado> crearEmpleado(
    Tienda tienda,
    String nombre,
    String cedula,
  ) async {
    final nombreLimpio = nombre.trim();
    final cedulaLimpia = cedula.trim();
    if (nombreLimpio.isEmpty || cedulaLimpia.isEmpty) {
      throw const ExcepcionDatosUsuarioNoValidos();
    }
    if (await _usuarios.buscarPorCedula(tienda, cedulaLimpia) != null) {
      throw const ExcepcionDatosUsuarioNoValidos();
    }
    final empleado = Empleado(const Uuid().v4(), nombreLimpio, cedulaLimpia);
    await _usuarios.guardar(tienda, empleado);
    return empleado;
  }

  /// Rechaza con [ExcepcionNoSePuedeDesactivar] si el usuario es
  /// [Administrador] (el propietario no se desactiva); si no, llama a
  /// `usuario.desactivar()` (que rechaza si ya está inactivo) y guarda con
  /// `usuarios.guardar`. No se borra: sus ventas y anulaciones siguen
  /// apuntando a él (RNF-15).
  ///
  /// Si guardar falla, `usuario` ya quedó inactivo en memoria y no en el
  /// servidor: quien llama vuelve a leer la lista (DI-42).
  Future<void> desactivar(Tienda tienda, Usuario usuario) async {
    if (usuario is Administrador) throw const ExcepcionNoSePuedeDesactivar();
    usuario.desactivar();
    await _usuarios.guardar(tienda, usuario);
  }
}
