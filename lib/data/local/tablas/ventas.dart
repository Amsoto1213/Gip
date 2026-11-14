import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Ventas confirmadas (clase `Venta`). Solo se agregan: la anulación será un
/// registro aparte (CUS-20, RNF-15). Sus salidas están en
/// `movimientos_inventario` con `venta_id` y sus pagos en `formas_pago`.
/// `fecha` en UTC (DI-13) hace de fecha de creación.
@DataClassName('FilaVenta')
@TableIndex(name: 'ventas_tienda_fecha_idx', columns: {#tiendaId, #fecha})
class Ventas extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();
  TextColumn get total => text().map(const ConversorDecimal())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
