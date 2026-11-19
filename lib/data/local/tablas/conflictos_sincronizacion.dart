import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Choque detectado al sincronizar que solo el propietario puede decidir
/// (clase `ConflictoSincronizacion`, CUS-22; los crea la conciliación, CUS-23).
/// Su `id` **no es un uuid**: es determinista (tipo y registros) para que dos
/// dispositivos que detectan el mismo choque no creen dos conflictos (DA-48).
/// `tipo` guarda el nombre del enum en mayúsculas (STOCK_NEGATIVO,
/// ABONO_EXCEDE_SALDO, CODIGO_REPETIDO, POSIBLE_DUPLICADO,
/// MOVIMIENTO_CAJA_CERRADA). `ids_registros` y `etiquetas_registros` son listas
/// de texto en JSON, una etiqueta por id y en el mismo orden (DI-45). `fecha`
/// en UTC (DI-13).
@DataClassName('FilaConflictoSincronizacion')
@TableIndex(name: 'conflictos_sincronizacion_tienda_idx', columns: {#tiendaId})
class ConflictosSincronizacion extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get tipo => text()();
  TextColumn get descripcion => text()();
  TextColumn get idsRegistros => text()();
  TextColumn get etiquetasRegistros => text()();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();
  BoolColumn get resuelto => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
