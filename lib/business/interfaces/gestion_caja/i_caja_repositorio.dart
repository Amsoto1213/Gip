import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a la caja; la
/// Data Layer lo implementa (RNF-08).
///
/// Por ahora solo las operaciones que usa el ingreso de una venta (CUS-02); el
/// cierre, la lista de movimientos y buscarPorId llegan con su caso de uso
/// (DI-21).
abstract interface class ICajaRepositorio {
  /// Caja de la jornada con sus movimientos, o null si todavía no se ha
  /// abierto. [fecha] es el día local, sin hora (DI-21).
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha);

  /// Inserta la caja si su id no existe (dos dispositivos pueden abrir la misma
  /// caja sin conexión, DA-62).
  Future<void> crear(Tienda tienda, Caja caja);

  /// Inserta solo el movimiento nuevo; nunca reescribe la caja ni los demás
  /// movimientos (DA-48, DA-62).
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  );
}
