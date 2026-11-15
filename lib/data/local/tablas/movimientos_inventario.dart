import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/items_inventario.dart';
import 'package:gip/data/local/tablas/ventas.dart';

/// Historial de movimientos de inventario (clase `MovimientoInventario` y sus
/// subclases) en una sola tabla con columna `tipo` (DI-03): ENTRADA, MERMA,
/// AJUSTE_CONTEO o SALIDA_VENTA. Solo se agregan filas; lo único que cambia
/// después es `estado` (VIGENTE, EN_REVISION, ANULADO), que pone la
/// conciliación o la anulación (RNF-15, DA-48).
///
/// `cantidad` lleva signo: positiva suma, negativa resta. `fecha` es la del
/// movimiento en UTC (DI-13) y hace de fecha de creación. Las columnas propias
/// de cada subclase son nulas en los otros tipos: ENTRADA usa
/// `costo_unitario` y `numero_factura`; SALIDA_VENTA, `venta_id`,
/// `precio_unitario` y `costo_unitario` (el precio de compra del momento,
/// nulo si no se conocía; DA-61, DI-21); MERMA, `motivo` (VENCIDO, DANADO,
/// DEVUELTO_PROVEEDOR u OTRO; DI-22); AJUSTE_CONTEO, `cantidad_contada` (lo
/// que se contó; `cantidad` es la diferencia con el stock, DI-24).
@DataClassName('FilaMovimientoInventario')
@TableIndex(name: 'movimientos_inventario_tienda_idx', columns: {#tiendaId})
@TableIndex(
  name: 'movimientos_inventario_item_tipo_fecha_idx',
  columns: {#itemId, #tipo, #fecha},
)
class MovimientosInventario extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get itemId => text().references(ItemsInventario, #id)();
  TextColumn get tipo => text()();
  TextColumn get cantidad => text().map(const ConversorDecimal())();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();
  TextColumn get estado => text()();
  TextColumn get costoUnitario =>
      text().map(const ConversorDecimal()).nullable()();
  TextColumn get numeroFactura => text().nullable()();
  TextColumn get ventaId => text().nullable().references(Ventas, #id)();
  TextColumn get precioUnitario =>
      text().map(const ConversorDecimal()).nullable()();
  TextColumn get motivo => text().nullable()();
  TextColumn get cantidadContada =>
      text().map(const ConversorDecimal()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
