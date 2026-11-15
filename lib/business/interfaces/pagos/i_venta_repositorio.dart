import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a las ventas; la
/// Data Layer lo implementa (RNF-08).
///
/// Por ahora [guardar] (CUS-02) y [listarPorPeriodo] (CUS-10); registrarAnulacion
/// llega con su caso de uso (DI-21, DI-29).
abstract interface class IVentaRepositorio {
  /// Guarda la venta con sus formas de pago en la misma transacción que sus
  /// salidas (RNF-04).
  Future<void> guardar(Tienda tienda, Venta venta);

  /// Ventas de la tienda con fecha en `[desde, hasta)`, cada una con sus formas
  /// de pago (contado, Nequi, fiado). Hasta CUS-20 ninguna está anulada; con
  /// ese caso de uso esta consulta dejará fuera las anuladas (DI-29).
  Future<List<Venta>> listarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );
}
