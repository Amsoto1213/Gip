import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_cuenta_acceso.dart';
import 'package:gip/business/interfaces/info_tienda/i_usuario_repositorio.dart';
import 'package:gip/transversal/configuracion/configuracion_usuarios.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de los usuarios de la tienda (CUS-15): lista, crea
/// empleados con su cuenta de acceso y los desactiva. La cuenta (correo y
/// contraseña) la crea Supabase Auth detrás de [ICuentaAcceso], fuera de la
/// Business Layer (DA-67, DI-43).
class ServicioUsuarios {
  ServicioUsuarios(this._usuarios, this._cuentas);

  final IUsuarioRepositorio _usuarios;
  final ICuentaAcceso _cuentas;

  static final _formaDeCorreo = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

  /// Llama a usuarios.listar(tienda): activos e inactivos.
  Future<List<Usuario>> listar(Tienda tienda) => _usuarios.listar(tienda);

  /// Creator: valida que el nombre y la cédula no estén vacíos y que
  /// `usuarios.buscarPorCedula(tienda, cedula)` no devuelva a otro usuario
  /// (activo o no); valida el [correo] y la [clave]; crea la cuenta de acceso
  /// con `cuentas.crear(correo, clave)`; y crea el [Empleado] con id nuevo,
  /// activo y con ese correo, y lo guarda con `usuarios.guardar`.
  ///
  /// Quita los espacios del inicio y del final del nombre, la cédula y el
  /// correo, y pasa el correo a minúsculas (el inicio de sesión lo busca así).
  /// La contraseña no se recorta ni se guarda: solo viaja a la cuenta. Todo se
  /// valida y se revisa la cédula **antes** de crear la cuenta, para no dejar
  /// una cuenta sin empleado. Si guardar falla después de crear la cuenta, el
  /// mismo intento se puede repetir (DI-43).
  ///
  /// Si algo no cumple lanza [ExcepcionDatosUsuarioNoValidos],
  /// [ExcepcionCorreoNoValido], [ExcepcionClaveNoValida] o
  /// [ExcepcionCorreoYaRegistrado] sin guardar nada (CUS-15, pasos 16 a 22).
  Future<Empleado> crearEmpleado(
    Tienda tienda,
    String nombre,
    String cedula,
    String correo,
    String clave,
  ) async {
    final nombreLimpio = nombre.trim();
    final cedulaLimpia = cedula.trim();
    final correoLimpio = correo.trim().toLowerCase();
    if (nombreLimpio.isEmpty || cedulaLimpia.isEmpty) {
      throw const ExcepcionDatosUsuarioNoValidos();
    }
    if (!_formaDeCorreo.hasMatch(correoLimpio)) {
      throw const ExcepcionCorreoNoValido();
    }
    if (clave.length < ConfiguracionUsuarios.largoMinimoClave) {
      throw const ExcepcionClaveNoValida(
        ConfiguracionUsuarios.largoMinimoClave,
      );
    }
    if (await _usuarios.buscarPorCedula(tienda, cedulaLimpia) != null) {
      throw const ExcepcionDatosUsuarioNoValidos();
    }
    await _cuentas.crear(correoLimpio, clave);
    final empleado = Empleado(
      const Uuid().v4(),
      nombreLimpio,
      cedulaLimpia,
      correo: correoLimpio,
    );
    await _usuarios.guardar(tienda, empleado);
    return empleado;
  }

  /// Rechaza con [ExcepcionNoSePuedeDesactivar] si el usuario es
  /// [Administrador] (el propietario no se desactiva); si no, llama a
  /// `usuario.desactivar()` (que rechaza si ya está inactivo) y guarda con
  /// `usuarios.guardar`. No se borra: sus ventas y anulaciones siguen
  /// apuntando a él (RNF-15). La cuenta de acceso no se toca: el inicio de
  /// sesión rechaza al usuario inactivo.
  ///
  /// Si guardar falla, `usuario` ya quedó inactivo en memoria y no en el
  /// servidor: quien llama vuelve a leer la lista (DI-42).
  Future<void> desactivar(Tienda tienda, Usuario usuario) async {
    if (usuario is Administrador) throw const ExcepcionNoSePuedeDesactivar();
    usuario.desactivar();
    await _usuarios.guardar(tienda, usuario);
  }
}
