import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_usuarios.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-15 Gestionar usuarios de la tienda: recibe
/// las operaciones del sistema desde la presentación y delega; no contiene
/// reglas de negocio. Cada operación exige que quien la pide sea el
/// propietario (RNF-12).
class GestionarUsuariosCoordinator {
  GestionarUsuariosCoordinator(this._servicioUsuarios, this._servicioAcceso);

  final ServicioUsuarios _servicioUsuarios;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioUsuarios.listar(tienda). Si no es el propietario lanza
  /// `ExcepcionSoloPropietario`.
  Future<List<Usuario>> listarUsuarios(Tienda tienda, Usuario usuario) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioUsuarios.listar(tienda);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioUsuarios.crearEmpleado(tienda, nombre, cedula).
  Future<Empleado> crearEmpleado(
    Tienda tienda,
    String nombre,
    String cedula,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioUsuarios.crearEmpleado(tienda, nombre, cedula);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioUsuarios.desactivar(tienda, empleado).
  Future<void> desactivarUsuario(
    Tienda tienda,
    Usuario empleado,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioUsuarios.desactivar(tienda, empleado);
  }
}
