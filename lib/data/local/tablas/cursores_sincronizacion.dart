import 'package:drift/drift.dart';

/// Hasta dónde bajó cada tabla de Supabase en esta tienda (CUS-23, DI-47).
/// `cursor` es el `sincronizado_en` más reciente que el servidor entregó, tal
/// como lo devolvió (texto, para no perder los microsegundos). Solo existe en
/// la base local y nunca se sube.
@DataClassName('FilaCursorSincronizacion')
class CursoresSincronizacion extends Table {
  TextColumn get tiendaId => text()();
  TextColumn get tabla => text()();
  TextColumn get cursor => text()();

  @override
  Set<Column<Object>> get primaryKey => {tiendaId, tabla};
}
