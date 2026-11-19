import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a la caja; la
/// Data Layer lo implementa (RNF-08).
///
/// Tiene las operaciones del ingreso de una venta (CUS-02), [listarMovimientos]
/// (CUS-10), [cerrar] (CUS-14), [buscarUltimaAnterior] (base de apertura) y
/// [buscarPorId] (CUS-22) (DI-21, DI-29, DI-37, DI-38, DI-45).
abstract interface class ICajaRepositorio {
  /// Caja de la jornada con sus movimientos, o null si todavía no se ha
  /// abierto. [fecha] es el día local, sin hora (DI-21).
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha);

  /// Caja de la tienda con ese id, con todos sus movimientos (también los que
  /// llegaron después del cierre) y los datos de su cierre, o null si no existe
  /// (CUS-22, DI-45). Su id se forma con la tienda y la fecha (DI-21).
  Future<Caja?> buscarPorId(Tienda tienda, String id);

  /// La caja más reciente con fecha anterior a [fecha] (día local, sin hora),
  /// con sus movimientos y su cierre, o null si no hay ninguna. De ella sale la
  /// base de apertura de la caja de [fecha] (DI-38).
  Future<Caja?> buscarUltimaAnterior(Tienda tienda, DateTime fecha);

  /// Inserta la caja con su base de apertura si su id no existe (dos dispositivos pueden abrir la misma
  /// caja sin conexión, DA-62).
  Future<void> crear(Tienda tienda, Caja caja);

  /// Inserta solo el movimiento nuevo; nunca reescribe la caja ni los demás
  /// movimientos (DA-48, DA-62).
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  );

  /// Guarda solo el cierre de la caja: cerrada, efectivoContado, diferencia y
  /// fechaCierre; no reescribe la caja ni los movimientos (RF-13, DA-48).
  Future<void> cerrar(Tienda tienda, Caja caja);

  /// Movimientos de caja de la tienda, de todas sus cajas, con fecha en
  /// `[desde, hasta)` (CUS-10, DI-29).
  Future<List<MovimientoCaja>> listarMovimientos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );
}
