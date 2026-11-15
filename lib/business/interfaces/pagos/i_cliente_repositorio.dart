import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los clientes;
/// la Data Layer lo implementa (RNF-08).
///
/// Por ahora [buscarPorNombre] y [guardar] (CUS-07); `eliminar` llega con
/// CUS-21 (DI-26).
abstract interface class IClienteRepositorio {
  /// Clientes de la tienda cuyo nombre contiene [texto], sin distinguir
  /// mayúsculas ni tildes (RD-08), cada uno con sus fiados.
  Future<List<Cliente>> buscarPorNombre(Tienda tienda, String texto);

  /// Crea o actualiza el cliente (RNF-16).
  Future<void> guardar(Tienda tienda, Cliente cliente);
}
