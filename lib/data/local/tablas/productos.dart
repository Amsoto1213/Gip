import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Catálogo de productos de cada tienda (clase `Producto`).
/// `codigo` tiene índice no único: la repetición entre dispositivos la reporta
/// la conciliación (DI-18, DA-59). `nombre_normalizado` (minúsculas, sin
/// tildes) sirve a la búsqueda por nombre (RD-08). `unidad_medida` guarda el
/// nombre del enum en mayúsculas (UNIDAD, KILOGRAMO, LIBRA).
@DataClassName('FilaProducto')
@TableIndex(name: 'productos_tienda_codigo_idx', columns: {#tiendaId, #codigo})
@TableIndex(
  name: 'productos_tienda_nombre_idx',
  columns: {#tiendaId, #nombreNormalizado},
)
class Productos extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  TextColumn get nombreNormalizado => text()();
  TextColumn get unidadMedida => text()();
  TextColumn get precioCompra =>
      text().map(const ConversorDecimal()).nullable()();
  TextColumn get precioVenta => text().map(const ConversorDecimal())();
  DateTimeColumn get actualizadoEn =>
      dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
