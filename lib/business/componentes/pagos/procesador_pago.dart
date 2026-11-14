import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Polymorphism y Protected Variations: cada forma de pago se procesa a su
/// manera. Un pago nuevo es una clase nueva, sin modificar ServicioVentas
/// (OCP).
abstract interface class ProcesadorPago {
  /// Indica si este procesador atiende esa forma de pago.
  bool admite(FormaPago forma);

  /// Aplica los efectos de la forma de pago al confirmar la venta. [venta] es
  /// el contexto: el de contado la usa en la descripción del movimiento de
  /// caja; los demás la ignoran.
  Future<void> procesar(Tienda tienda, Venta venta, FormaPago forma);

  /// Deshace los efectos de la forma de pago al anular la venta (CUS-20).
  Future<void> revertir(Tienda tienda, Venta venta, FormaPago forma);
}
