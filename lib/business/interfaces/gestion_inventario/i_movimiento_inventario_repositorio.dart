import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso al historial de
/// movimientos de inventario; la Data Layer lo implementa (RNF-08).
///
/// Las operaciones de CUS-01, CUS-24, CUS-09, CUS-10, CUS-25, CUS-20, CUS-22
/// y CUS-23;
/// las demás de EA llegan con su caso de uso (DI-20, DI-25, DI-32, DI-39,
/// DI-45, DI-46).
abstract interface class IMovimientoInventarioRepositorio {
  /// Agrega el movimiento al historial; nunca lo modifica (RF-01 a RF-04).
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento);

  /// Historial del ítem con fecha en `[desde, hasta)`, del más reciente al más
  /// antiguo: entradas, salidas, mermas y ajustes, en cualquier estado
  /// (VIGENTE, EN_REVISION o ANULADO). Lo usa el panel de existencias (CUS-25,
  /// DI-32).
  Future<List<MovimientoInventario>> listarPorItem(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  );

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

  /// Salidas VIGENTES por venta de toda la tienda con fecha en `[desde, hasta)`,
  /// cada una con su ítem, su producto y el precio y el costo con que se
  /// vendió; las usan los reportes (RF-08, CUS-09, DI-28). Las de ventas
  /// anuladas no cuentan.
  Future<List<SalidaVenta>> listarSalidasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Entradas VIGENTES de la tienda con fecha en `[desde, hasta)`, con su ítem
  /// y su producto (CUS-10, DI-29).
  Future<List<EntradaMercancia>> listarEntradasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Fecha del primer movimiento del ítem, de cualquier tipo y estado, o null
  /// si no tiene: marca el inicio de su historial para los días con datos del
  /// consumo (DI-25; no está en EA).
  Future<DateTime?> buscarFechaPrimerMovimiento(ItemInventario item);

  /// Salidas por venta de las ventas con esos ids ([idsVentas]), en cualquier estado (VIGENTE o
  /// ANULADO), cada una con su ítem y su producto. Sirve para anular las
  /// salidas de una venta y para mostrar sus productos (CUS-20). En EA es
  /// `listarSalidasPorVenta(venta)`: aquí recibe la tienda y varias ventas
  /// juntas (DI-39), y solo sus ids, para no depender de `Venta` (DI-63).
  Future<List<SalidaVenta>> listarSalidasPorVentas(
    Tienda tienda,
    List<String> idsVentas,
  );

  /// Movimientos de la tienda con esos ids, en cualquier estado (VIGENTE,
  /// EN_REVISION o ANULADO), cada uno con su ítem y su producto. Los usa la
  /// resolución de un conflicto de entradas repetidas o de stock negativo
  /// (CUS-22, DI-45). Los ids que no existan no aparecen.
  Future<List<MovimientoInventario>> buscarPorIds(
    Tienda tienda,
    List<String> ids,
  );

  /// Todos los movimientos de la tienda con fecha en `[desde, hasta)`, de los
  /// cuatro tipos y en cualquier estado (VIGENTE, EN_REVISION o ANULADO), del
  /// más antiguo al más reciente, cada uno con su ítem y su producto. Los usa
  /// la conciliación para buscar entradas repetidas y los ítems que recibieron
  /// movimientos (CUS-23, DI-46).
  Future<List<MovimientoInventario>> listarPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  );

  /// Guarda solo el estado del movimiento (VIGENTE, EN_REVISION o ANULADO);
  /// nunca reescribe lo demás (RNF-15). Se une a la transacción abierta.
  Future<void> actualizarEstado(Tienda tienda, MovimientoInventario movimiento);
}
