import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los fiados; la
/// Data Layer lo implementa (RNF-08).
///
/// Por ahora solo [crear] (CUS-07); las demás operaciones de EA llegan con
/// CUS-08, CUS-19 y CUS-20 (DI-26).
abstract interface class IFiadoRepositorio {
  /// Inserta el fiado nuevo (sin abonos) cuando se confirma una venta fiada
  /// (CUR-07). Se une a la transacción abierta de la venta (RNF-04).
  Future<void> crear(Tienda tienda, Fiado fiado);
}
