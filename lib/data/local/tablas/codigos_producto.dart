import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/productos.dart';

/// Códigos de barras o QR asociados a un producto (clase `CodigoProducto`,
/// CUS-17 y CUS-18 "Asociar código"). `valor` guarda el texto exacto de la
/// lectura (DA-41) y `formato` el nombre del enum en mayúsculas (EAN13, EAN8,
/// UPCA, QR). El índice de `(tienda_id, valor)` **no** es único: dos equipos
/// sin conexión pueden asociar el mismo valor a productos distintos y eso lo
/// reporta CUS-22 (`listarCodigosRepetidos`, DA-66). La regla de no repetir la
/// valida `ServicioCatalogo.asociarCodigo`. `creado_en` en UTC (DI-13).
@DataClassName('FilaCodigoProducto')
@TableIndex(
  name: 'codigos_producto_tienda_valor_idx',
  columns: {#tiendaId, #valor},
)
@TableIndex(name: 'codigos_producto_producto_idx', columns: {#productoId})
class CodigosProducto extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get productoId => text().references(Productos, #id)();
  TextColumn get formato => text()();
  TextColumn get valor => text()();
  DateTimeColumn get creadoEn => dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
