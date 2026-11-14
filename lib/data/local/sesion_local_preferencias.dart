import 'dart:convert';

import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/data/helpers/conversor_usuario_activo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el usuario activo (con su tienda y su rol) como JSON en
/// shared_preferences (DI-12). shared_preferences solo se usa aquí, detrás de
/// [ISesionLocal]; se puede cambiar por una tabla drift sin tocar otras capas.
class SesionLocalPreferencias implements ISesionLocal {
  SesionLocalPreferencias(this._preferencias);

  static const _clave = 'gip.usuario_activo';

  final SharedPreferencesAsync _preferencias;

  @override
  Future<void> guardar(UsuarioActivo usuarioActivo) => _preferencias.setString(
    _clave,
    jsonEncode(ConversorUsuarioActivo.aFila(usuarioActivo)),
  );

  @override
  Future<UsuarioActivo?> leer() async {
    final json = await _preferencias.getString(_clave);
    if (json == null) return null;
    try {
      return ConversorUsuarioActivo.desdeFila(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } on Object {
      // Dato dañado o de otra versión: se pide iniciar sesión de nuevo.
      await borrar();
      return null;
    }
  }

  @override
  Future<void> borrar() => _preferencias.remove(_clave);
}
