import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Usuario que inició sesión en este dispositivo y la tienda que atiende (DI-11).
/// El rol es la subclase de [Usuario].
typedef UsuarioActivo = ({Usuario usuario, Tienda tienda});
