import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';

/// Caja del día de cada tienda (clase `Caja`). El id no es un UUID: se forma
/// con la tienda y la fecha (`<tienda_id>_AAAA-MM-DD`) para que dos
/// dispositivos sin conexión abran la misma caja (DA-62, DI-21). `fecha` es el
/// día local como texto "AAAA-MM-DD", no un instante (DI-21). El saldo no se
/// guarda: se calcula de los movimientos (DA-48). Las columnas del cierre
/// (`cerrada`, `efectivo_contado`, `diferencia` y `fecha_cierre`) se llenan
/// juntas al cerrar la caja (CUS-14, DI-37): mientras está abierta, `cerrada`
/// es falso y las otras tres son nulas. `fecha_cierre` es el instante del
/// cierre en UTC (DI-13) y hace de fecha de última modificación.
/// `base_apertura` es el efectivo con el que abrió la caja, calculado al
/// crearla (CUS-14, DI-38); no cambia después.
@DataClassName('FilaCaja')
@TableIndex(name: 'cajas_tienda_idx', columns: {#tiendaId})
class Cajas extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get fecha => text()();
  TextColumn get baseApertura =>
      text().map(const ConversorDecimal()).withDefault(const Constant('0'))();
  BoolColumn get cerrada => boolean().withDefault(const Constant(false))();
  TextColumn get efectivoContado =>
      text().map(const ConversorDecimal()).nullable()();
  TextColumn get diferencia =>
      text().map(const ConversorDecimal()).nullable()();
  DateTimeColumn get fechaCierre =>
      dateTime().map(const ConversorFechaUtc()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
