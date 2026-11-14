import 'package:gip/transversal/errores/errores_acceso.dart';

/// Usuario del sistema; su rol es la subclase ([Empleado] o [Administrador]),
/// RNF-12. Se crea y se desactiva en CUS-15; no se borra.
class Usuario {
  Usuario(this._id, this._nombre, this._cedula, {this._activo = true});

  final String _id;
  final String _nombre;
  final String _cedula;
  bool _activo;

  String getId() => _id;

  String getNombre() => _nombre;

  String getCedula() => _cedula;

  /// Verdadero si puede usar el sistema.
  bool isActivo() => _activo;

  /// Information Expert: rechaza si ya está inactivo; si no, queda inactivo.
  void desactivar() {
    if (!_activo) throw const ExcepcionUsuarioYaInactivo();
    _activo = false;
  }
}

/// Usuario que atiende el mostrador (actor Empleado).
class Empleado extends Usuario {
  Empleado(super.id, super.nombre, super.cedula, {super.activo});
}

/// Propietario: hereda lo del empleado y accede a reportes y caja (RNF-12).
class Administrador extends Usuario {
  Administrador(super.id, super.nombre, super.cedula, {super.activo});
}
