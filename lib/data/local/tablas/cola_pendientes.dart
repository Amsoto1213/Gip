import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Escrituras locales que faltan por subir a Supabase. Cada escritura agrega
/// su fila en la misma transacción (DA-33).
@DataClassName('EntradaCola')
class ColaPendientes extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get tabla => text()();
  TextColumn get registroId => text()();
  TextColumn get operacion => text()();
  IntColumn get intentos => integer().withDefault(const Constant(0))();
  DateTimeColumn get creadoEn => dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
