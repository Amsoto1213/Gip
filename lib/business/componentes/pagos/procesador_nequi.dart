import 'package:gip/business/componentes/pagos/procesador_pago.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Pago por Nequi: no mueve la caja, porque el dinero no entra al efectivo que
/// se cuenta al cierre (DA-63).
class ProcesadorNequi implements ProcesadorPago {
  ProcesadorNequi();

  @override
  bool admite(FormaPago forma) => forma is PagoNequi;

  /// No registra movimientos de caja: el pago queda guardado con la venta.
  @override
  Future<void> procesar(Tienda tienda, Venta venta, FormaPago forma) async {}

  /// No registra movimientos de caja: la devolución se hace por Nequi, fuera
  /// del sistema.
  @override
  Future<void> revertir(Tienda tienda, Venta venta, FormaPago forma) async {}
}
