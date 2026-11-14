import 'package:drift/drift.dart';

/// Toda fecha se guarda en UTC y se lee en UTC (DI-13). Con
/// `store_date_time_values_as_text` queda como texto ISO-8601 terminado en `Z`,
/// que pasa directo a `timestamptz` en Supabase. La hora local es solo para
/// mostrar.
class ConversorFechaUtc extends TypeConverter<DateTime, DateTime> {
  const ConversorFechaUtc();

  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toUtc();

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
