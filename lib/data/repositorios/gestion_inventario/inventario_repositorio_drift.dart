import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/mapeo_producto.dart';

/// [IInventarioRepositorio] sobre la base local (drift). Toda consulta filtra
/// por `tienda_id`. `stock_actual` no se sube a Supabase: allá solo va la fila
/// del ítem (DI-17).
class InventarioRepositorioDrift implements IInventarioRepositorio {
  InventarioRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'items_inventario';

  @override
  Future<ItemInventario?> buscarItem(Tienda tienda, Producto producto) async {
    final fila =
        await (_base.select(_base.itemsInventario)..where(
              (i) =>
                  i.tiendaId.equals(tienda.getId()) &
                  i.productoId.equals(producto.getId()),
            ))
            .getSingleOrNull();
    return fila == null
        ? null
        : ItemInventario(fila.id, producto, fila.stockActual);
  }

  @override
  Future<List<ItemInventario>> listarItems(Tienda tienda) async {
    final consulta =
        _base.select(_base.itemsInventario).join([
            innerJoin(
              _base.productos,
              _base.productos.id.equalsExp(_base.itemsInventario.productoId),
            ),
          ])
          ..where(_base.itemsInventario.tiendaId.equals(tienda.getId()))
          ..orderBy([OrderingTerm.asc(_base.productos.nombreNormalizado)]);
    final filas = await consulta.get();
    return filas.map((f) {
      final item = f.readTable(_base.itemsInventario);
      final producto = MapeoProducto.aEntidad(f.readTable(_base.productos));
      return ItemInventario(item.id, producto, item.stockActual);
    }).toList();
  }

  /// Crea o actualiza el ítem y lo anota en `cola_pendientes` en la misma
  /// transacción (DA-33); se une a la transacción abierta si la hay.
  @override
  Future<void> guardarItem(Tienda tienda, ItemInventario item) =>
      _base.transaction(() async {
        final existe =
            await (_base.select(
              _base.itemsInventario,
            )..where((i) => i.id.equals(item.getId()))).getSingleOrNull() !=
            null;
        await _base
            .into(_base.itemsInventario)
            .insertOnConflictUpdate(
              ItemsInventarioCompanion.insert(
                id: item.getId(),
                tiendaId: tienda.getId(),
                productoId: item.getProducto().getId(),
                stockActual: item.getStockActual(),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: item.getId(),
          operacion: existe ? OperacionCola.actualizar : OperacionCola.insertar,
        );
      });
}
