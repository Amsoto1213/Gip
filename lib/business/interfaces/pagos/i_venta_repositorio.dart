import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a las ventas; la
/// Data Layer lo implementa (RNF-08).
///
/// Por ahora solo [guardar] (CUS-02); listarPorPeriodo y registrarAnulacion
/// llegan con su caso de uso (DI-21).
abstract interface class IVentaRepositorio {
  /// Guarda la venta con sus formas de pago en la misma transacción que sus
  /// salidas (RNF-04).
  Future<void> guardar(Tienda tienda, Venta venta);
}
