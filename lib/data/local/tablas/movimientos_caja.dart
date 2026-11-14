import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/cajas.dart';

/// Movimientos de dinero de la caja (clase `MovimientoCaja`). Solo se agregan
/// (DA-48). `tipo` es INGRESO o EGRESO; `clasificacion`, NEGOCIO, PERSONAL o
/// ANULACION. `valor` siempre es positivo. `fecha` es la del movimiento en UTC
/// (DI-13) y hace de fecha de creación.
@DataClassName('FilaMovimientoCaja')
@TableIndex(name: 'movimientos_caja_tienda_idx', columns: {#tiendaId})
@TableIndex(name: 'movimientos_caja_caja_idx', columns: {#cajaId})
class MovimientosCaja extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get cajaId => text().references(Cajas, #id)();
  TextColumn get tipo => text()();
  TextColumn get clasificacion => text()();
  TextColumn get valor => text().map(const ConversorDecimal())();
  TextColumn get descripcion => text()();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
