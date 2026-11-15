import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso al historial de
/// movimientos de inventario; la Data Layer lo implementa (RNF-08).
///
/// Por ahora solo las operaciones de CUS-01 y CUS-24; las demás de EA llegan
/// con su caso de uso (DI-20, DI-25).
abstract interface class IMovimientoInventarioRepositorio {
  /// Agrega el movimiento al historial; nunca lo modifica (RF-01 a RF-04).
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento);

  /// Última entrada VIGENTE del ítem; permite comparar el costo (IE-02). Las
  /// anuladas o en revisión no cuentan (DI-20).
  Future<EntradaMercancia?> buscarUltimaEntrada(ItemInventario item);

  /// Salidas VIGENTES por venta del ítem con fecha en `[desde, hasta)`: base del
  /// consumo promedio (RF-05). Cada una trae solo el id y la fecha de su venta
  /// (DI-25).
  Future<List<SalidaVenta>> listarSalidas(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  );

  /// Fecha del primer movimiento del ítem, de cualquier tipo y estado, o null
  /// si no tiene: marca el inicio de su historial para los días con datos del
  /// consumo (DI-25; no está en EA).
  Future<DateTime?> buscarFechaPrimerMovimiento(ItemInventario item);
}
