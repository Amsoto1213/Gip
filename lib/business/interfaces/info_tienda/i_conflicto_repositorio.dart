import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los conflictos
/// de sincronización; la Data Layer lo implementa (RNF-08, DI-45). Toda
/// operación recibe la tienda (RNF-13).
abstract interface class IConflictoRepositorio {
  /// Inserta el conflicto si su id no existe: dos dispositivos pueden detectar
  /// el mismo choque (DA-48). Si ya existe no lo toca, ni siquiera si ya
  /// estaba resuelto. Lo usa la detección (CUS-23).
  Future<void> guardar(Tienda tienda, ConflictoSincronizacion conflicto);

  /// Conflictos sin resolver de la tienda, del más antiguo al más reciente.
  Future<List<ConflictoSincronizacion>> listarPendientes(Tienda tienda);

  /// Guarda que el conflicto fue resuelto. Se une a la transacción abierta.
  Future<void> marcarResuelto(Tienda tienda, ConflictoSincronizacion conflicto);
}
