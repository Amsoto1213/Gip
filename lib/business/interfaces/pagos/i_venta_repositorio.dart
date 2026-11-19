import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a las ventas; la
/// Data Layer lo implementa (RNF-08).
///
/// [guardar] (CUS-02), [listarPorPeriodo] (CUS-10 y CUS-20) y
/// [registrarAnulacion] (CUS-20) (DI-21, DI-29, DI-39).
abstract interface class IVentaRepositorio {
  /// Guarda la venta con sus formas de pago en la misma transacción que sus
  /// salidas (RNF-04).
  Future<void> guardar(Tienda tienda, Venta venta);

  /// Ventas de la tienda con fecha en `[desde, hasta)`, cada una con sus formas
  /// de pago (contado, Nequi, fiado; el fiado con sus abonos) y su anulación,
  /// si la tiene. Trae también las anuladas: quien suma (los reportes) decide
  /// con `isAnulada` (DI-29, DI-39).
  Future<List<Venta>> listarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Inserta la anulación de la venta; la venta no se modifica (RNF-15,
  /// DA-48). Se une a la transacción de ServicioVentas.anular.
  Future<void> registrarAnulacion(
    Tienda tienda,
    Venta venta,
    AnulacionVenta anulacion,
  );
}
