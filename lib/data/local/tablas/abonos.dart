import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/fiados.dart';

/// Abonos de los fiados (clase `Abono`). Solo se agregan: si hay que deshacer
/// uno se marca `anulado`, nunca se borra (RNF-15). `medio` es EFECTIVO o NEQUI
/// (DA-64); `referencia` solo va con NEQUI. `fecha` en UTC (DI-13). El saldo
/// del fiado es una copia local del cálculo (DA-30, DI-27).
@DataClassName('FilaAbono')
@TableIndex(name: 'abonos_tienda_idx', columns: {#tiendaId})
@TableIndex(name: 'abonos_fiado_idx', columns: {#fiadoId})
class Abonos extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get fiadoId => text().references(Fiados, #id)();
  TextColumn get monto => text().map(const ConversorDecimal())();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();
  TextColumn get medio => text()();
  TextColumn get referencia => text().nullable()();
  BoolColumn get anulado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
