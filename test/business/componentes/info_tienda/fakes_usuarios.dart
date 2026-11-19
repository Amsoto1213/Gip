import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_cuenta_acceso.dart';
import 'package:gip/business/interfaces/info_tienda/i_usuario_repositorio.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';

/// Usuarios en memoria, por tienda. Como una base de datos: guarda y devuelve
/// copias, así cambiar un usuario leído no cambia lo guardado hasta que se
/// llama a [guardar]. [fallar] simula una falla de la red.
class UsuarioRepositorioFalso implements IUsuarioRepositorio {
  final Map<String, List<Usuario>> _datos = {};

  /// Cada vez que se guardó un usuario, en orden de llegada (copias).
  final List<Usuario> guardados = [];

  bool fallar = false;

  /// Falla solo al guardar: lo demás sigue funcionando.
  bool fallarAlGuardar = false;

  static Usuario _copiar(Usuario u) => u is Administrador
      ? Administrador(
          u.getId(),
          u.getNombre(),
          u.getCedula(),
          correo: u.getCorreo(),
          activo: u.isActivo(),
        )
      : Empleado(
          u.getId(),
          u.getNombre(),
          u.getCedula(),
          correo: u.getCorreo(),
          activo: u.isActivo(),
        );

  List<Usuario> _de(Tienda t) => _datos.putIfAbsent(t.getId(), () => []);

  /// Deja un usuario ya guardado, sin contarlo en [guardados].
  void sembrar(Tienda tienda, Usuario usuario) =>
      _de(tienda).add(_copiar(usuario));

  @override
  Future<List<Usuario>> listar(Tienda tienda) async {
    if (fallar) throw StateError('sin red');
    return _de(tienda).map(_copiar).toList()..sort((a, b) {
      final porRol = (a is Administrador ? 0 : 1).compareTo(
        b is Administrador ? 0 : 1,
      );
      return porRol != 0 ? porRol : a.getNombre().compareTo(b.getNombre());
    });
  }

  @override
  Future<Usuario?> buscarPorCedula(Tienda tienda, String cedula) async {
    if (fallar) throw StateError('sin red');
    final u = _de(tienda).where((u) => u.getCedula() == cedula).firstOrNull;
    return u == null ? null : _copiar(u);
  }

  @override
  Future<void> guardar(Tienda tienda, Usuario usuario) async {
    if (fallar || fallarAlGuardar) throw StateError('sin red');
    final copia = _copiar(usuario);
    guardados.add(copia);
    final lista = _de(tienda);
    final i = lista.indexWhere((u) => u.getId() == usuario.getId());
    if (i >= 0) {
      lista[i] = copia;
    } else {
      lista.add(copia);
    }
  }
}

/// Cuentas de acceso en memoria: correo → contraseña. Cumple lo que promete
/// `ICuentaAcceso.crear`: con el mismo correo y la misma contraseña da por
/// buena la cuenta que ya existe; con otra contraseña, el correo es de alguien
/// más. [fallar] simula una falla de la red.
class CuentaAccesoFalsa implements ICuentaAcceso {
  final Map<String, String> cuentas = {};

  /// Cada llamada a crear, en orden de llegada: (correo, clave).
  final List<(String, String)> intentos = [];

  bool fallar = false;

  @override
  Future<void> crear(String correo, String clave) async {
    intentos.add((correo, clave));
    if (fallar) throw StateError('sin red');
    final existente = cuentas[correo];
    if (existente != null && existente != clave) {
      throw const ExcepcionCorreoYaRegistrado();
    }
    cuentas[correo] = clave;
  }
}
