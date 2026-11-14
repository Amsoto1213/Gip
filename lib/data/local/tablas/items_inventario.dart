import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/tablas/productos.dart';

/// Stock de cada producto en la tienda (clase `ItemInventario`). Un ítem por
/// producto. `stock_actual` solo existe en el dispositivo: se recalcula de los
/// movimientos y no se sincroniza como número (DI-17).
@DataClassName('FilaItemInventario')
@TableIndex(name: 'items_inventario_tienda_idx', columns: {#tiendaId})
class ItemsInventario extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get productoId => text().references(Productos, #id)();
  TextColumn get stockActual => text().map(const ConversorDecimal())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {tiendaId, productoId},
  ];
}
