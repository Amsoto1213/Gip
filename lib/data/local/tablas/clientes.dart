import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Clientes del fiado de cada tienda (clase `Cliente`): solo nombre y teléfono
/// (RNF-16). `telefono` vacío ('') si no lo dio (DI-26). `nombre_normalizado`
/// (minúsculas, sin tildes) sirve a la búsqueda por nombre (RD-08).
/// `actualizado_en` lo pone la app: gana la edición más reciente (DA-48).
@DataClassName('FilaCliente')
@TableIndex(
  name: 'clientes_tienda_nombre_idx',
  columns: {#tiendaId, #nombreNormalizado},
)
class Clientes extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get nombre => text()();
  TextColumn get nombreNormalizado => text()();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  DateTimeColumn get actualizadoEn =>
      dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
