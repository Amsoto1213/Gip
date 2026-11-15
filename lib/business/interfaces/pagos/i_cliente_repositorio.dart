import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los clientes;
/// la Data Layer lo implementa (RNF-08).
///
/// [buscarPorNombre] y [guardar] (CUS-07) y [eliminar] (CUS-21, DI-26 y
/// DI-31).
abstract interface class IClienteRepositorio {
  /// Clientes de la tienda cuyo nombre contiene [texto], sin distinguir
  /// mayúsculas ni tildes (RD-08), cada uno con sus fiados y los abonos de
  /// cada fiado (CUS-08, CUS-19).
  Future<List<Cliente>> buscarPorNombre(Tienda tienda, String texto);

  /// Crea o actualiza el cliente (RNF-16).
  Future<void> guardar(Tienda tienda, Cliente cliente);

  /// Elimina los datos personales del cliente cuando no tiene fiados
  /// pendientes (CUS-21, RNF-16). Sus fiados, abonos y ventas se conservan
  /// (RNF-15); [buscarPorNombre] ya no lo devuelve.
  Future<void> eliminar(Tienda tienda, Cliente cliente);
}
