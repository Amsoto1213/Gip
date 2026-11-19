import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a los fiados; la
/// Data Layer lo implementa (RNF-08).
///
/// [crear] (CUS-07), [registrarAbono] (CUS-08), [listarAbonos] (CUS-10) y
/// [actualizarSaldo] (CUS-20); las demás operaciones de EA llegan con CUS-19 y
/// CUS-23 (DI-26, DI-27, DI-29, DI-39).
abstract interface class IFiadoRepositorio {
  /// Inserta el fiado nuevo (sin abonos) cuando se confirma una venta fiada
  /// (CUR-07). Se une a la transacción abierta de la venta (RNF-04).
  Future<void> crear(Tienda tienda, Fiado fiado);

  /// Inserta solo el abono nuevo y actualiza solo el saldo y el estado del
  /// fiado, en una transacción (CUR-08, RNF-04, DA-46). Se une a la
  /// transacción de ServicioAbonos.
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono);

  /// Abonos de la tienda con fecha en `[desde, hasta)`, con los anulados: cada
  /// abono dice si lo está (`isAnulado`) y quien suma decide (DI-29).
  Future<List<Abono>> listarAbonos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Guarda solo el saldo y el estado del fiado (por ejemplo, al anularlo);
  /// no toca sus abonos (CUS-20). Se une a la transacción abierta.
  Future<void> actualizarSaldo(Tienda tienda, Fiado fiado);
}
