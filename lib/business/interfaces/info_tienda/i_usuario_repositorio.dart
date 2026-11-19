import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los usuarios
/// de la tienda; la Data Layer lo implementa (RNF-08). Los usuarios viven en el
/// servidor, junto a las cuentas de acceso (DI-42). Toda operación recibe la
/// tienda (RNF-13).
abstract interface class IUsuarioRepositorio {
  /// Usuarios de la tienda, activos e inactivos: primero el propietario y
  /// luego los empleados, cada grupo por nombre.
  Future<List<Usuario>> listar(Tienda tienda);

  /// Usuario de la tienda con esa cédula (activo o no), o null.
  Future<Usuario?> buscarPorCedula(Tienda tienda, String cedula);

  /// Crea o actualiza el usuario (nombre, cédula, rol y activo).
  Future<void> guardar(Tienda tienda, Usuario usuario);
}
