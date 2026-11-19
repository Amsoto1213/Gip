import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/gestionar_usuarios_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Usuarios de la tienda (CUS-15). Llama solo a
/// [GestionarUsuariosCoordinator]. Después de cada intento de agregar o
/// desactivar vuelve a leer la lista: si guardar falló, el usuario ya quedó
/// inactivo en memoria y la lista debe mostrar lo que hay en el servidor
/// (DI-42).
class UsuariosViewModel extends ChangeNotifier {
  UsuariosViewModel(this._coordinador, this._usuarioActivo);

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  static const mensajeEmpleadoCreado = 'Empleado creado';
  static const mensajeEmpleadoDesactivado = 'Empleado desactivado';

  static const _mensajeFalla = 'No se pudo completar. Intente de nuevo';

  final GestionarUsuariosCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;

  bool _cargando = false;
  bool _ocupado = false;
  String? _errorCarga;
  String? _error;
  String? _mensajeListo;
  List<Usuario> _usuarios = const [];

  /// Leyendo la lista.
  bool get cargando => _cargando;

  /// Agregando o desactivando: se bloquean los botones.
  bool get ocupado => _ocupado;

  /// No se pudo leer la lista (sin internet, no es el propietario…).
  String? get errorCarga => _errorCarga;

  /// No se pudo agregar o desactivar.
  String? get error => _error;

  /// "Empleado creado" o "Empleado desactivado".
  String? get mensajeListo => _mensajeListo;

  /// Activos e inactivos: primero el propietario, luego los empleados.
  List<Usuario> get usuarios => _usuarios;

  /// Verdadero si [usuario] es quien tiene la sesión abierta ("usted").
  bool esUsted(Usuario usuario) =>
      usuario.getId() == _usuarioActivo.usuario.getId();

  /// Se puede desactivar: solo a un empleado activo (el propietario no se
  /// desactiva y a un inactivo no hay nada que hacerle).
  bool puedeDesactivarse(Usuario usuario) =>
      usuario is! Administrador && usuario.isActivo();

  Future<void> cargar() async {
    _cargando = true;
    _errorCarga = null;
    notifyListeners();
    try {
      _usuarios = await _coordinador.listarUsuarios(
        _usuarioActivo.tienda,
        _usuarioActivo.usuario,
      );
    } catch (e) {
      _usuarios = const [];
      _errorCarga = _texto(e);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Crea el empleado con su cuenta de acceso y vuelve a leer la lista.
  /// Devuelve verdadero si quedó creado, para que la pantalla limpie el
  /// formulario (DI-43).
  Future<bool> agregar(
    String nombre,
    String cedula,
    String correo,
    String clave,
  ) async {
    if (_ocupado) return false;
    _empezar();
    var creado = false;
    try {
      await _coordinador.crearEmpleado(
        _usuarioActivo.tienda,
        nombre,
        cedula,
        correo,
        clave,
        _usuarioActivo.usuario,
      );
      _mensajeListo = mensajeEmpleadoCreado;
      creado = true;
    } catch (e) {
      _error = _texto(e);
    }
    await _terminar();
    return creado;
  }

  /// Desactiva al empleado y vuelve a leer la lista.
  Future<void> desactivar(Usuario empleado) async {
    if (_ocupado) return;
    _empezar();
    try {
      await _coordinador.desactivarUsuario(
        _usuarioActivo.tienda,
        empleado,
        _usuarioActivo.usuario,
      );
      _mensajeListo = mensajeEmpleadoDesactivado;
    } catch (e) {
      _error = _texto(e);
    }
    await _terminar();
  }

  void _empezar() {
    _ocupado = true;
    _error = null;
    _mensajeListo = null;
    notifyListeners();
  }

  Future<void> _terminar() async {
    try {
      _usuarios = await _coordinador.listarUsuarios(
        _usuarioActivo.tienda,
        _usuarioActivo.usuario,
      );
      _errorCarga = null;
    } catch (_) {
      // Si no se pudo releer, se deja la lista que había y el aviso del
      // intento; arrastrar para actualizar vuelve a intentarlo.
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  static String _texto(Object e) => switch (e) {
    ExcepcionSoloPropietario() => mensajeSoloPropietario,
    ExcepcionNegocio() => e.mensaje,
    _ => _mensajeFalla,
  };
}
