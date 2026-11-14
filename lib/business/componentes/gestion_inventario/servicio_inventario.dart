import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert del stock: crea los movimientos y
/// mantiene el stock con stock nuevo = stock anterior + cantidad con signo
/// (ERS 3.2.1).
///
/// Por ahora solo tiene [crearItem] (CUS-18). `movimientos`,
/// `umbralRevisionConteo` y `unidadTrabajo` están en el constructor de EA y
/// los usarán CUS-01, CUS-03 y CUS-04 (DI-15).
class ServicioInventario {
  ServicioInventario(
    this._items,
    this._movimientos,
    this._umbralRevisionConteo,
    this._unidadTrabajo,
  );

  final IInventarioRepositorio _items;

  // Pendientes (DI-15): CUS-01, CUS-03 y CUS-04.
  // ignore: unused_field
  final IMovimientoInventarioRepositorio _movimientos;
  // ignore: unused_field
  final Decimal _umbralRevisionConteo;
  // ignore: unused_field
  final IUnidadTrabajo _unidadTrabajo;

  /// Creator: crea el [ItemInventario] con id nuevo y stock cero y lo guarda
  /// con items.guardarItem. Lo llama `ServicioCatalogo.crearProducto` dentro de
  /// su transacción.
  Future<ItemInventario> crearItem(Tienda tienda, Producto producto) async {
    final item = ItemInventario(const Uuid().v4(), producto, Decimal.zero);
    await _items.guardarItem(tienda, item);
    return item;
  }
}
