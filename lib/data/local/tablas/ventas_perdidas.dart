import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/productos.dart';

/// Ventas perdidas por producto agotado (clase `VentaPerdida`, RF-12). Solo
/// se agregan (DA-48, DA-50): las registra CUS-13; CUS-24 y CUS-05 solo las
/// leen (DI-25). `fecha` en UTC (DI-13) hace de fecha de creación.
@DataClassName('FilaVentaPerdida')
@TableIndex(
  name: 'ventas_perdidas_tienda_fecha_idx',
  columns: {#tiendaId, #fecha},
)
@TableIndex(
  name: 'ventas_perdidas_producto_fecha_idx',
  columns: {#productoId, #fecha},
)
class VentasPerdidas extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get productoId => text().references(Productos, #id)();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
