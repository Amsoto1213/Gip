import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/tablas/items_inventario.dart';

/// Alertas de reabastecimiento del día (clase `AlertaReabastecimiento`,
/// CUS-24). `fecha` es el día local como texto "AAAA-MM-DD", como en `cajas`
/// (DI-21): las alertas son de un día calendario. No se editan: cada cálculo
/// borra las del día y escribe las nuevas (`reemplazar`, RD-11, DA-35, DI-25).
@DataClassName('FilaAlerta')
@TableIndex(
  name: 'alertas_reabastecimiento_tienda_fecha_idx',
  columns: {#tiendaId, #fecha},
)
class AlertasReabastecimiento extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get itemId => text().references(ItemsInventario, #id)();
  TextColumn get fecha => text()();
  TextColumn get existencia => text().map(const ConversorDecimal())();
  TextColumn get consumoPromedioDiario =>
      text().map(const ConversorDecimal())();
  TextColumn get diasCobertura => text().map(const ConversorDecimal())();
  BoolColumn get provisional => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
