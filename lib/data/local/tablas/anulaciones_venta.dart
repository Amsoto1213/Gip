import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/ventas.dart';

/// Anulación de una venta (clase `AnulacionVenta`, CUS-20): quién, cuándo y por
/// qué (RNF-15). Es un registro aparte: la venta no se borra ni cambia sus
/// datos, y esta fila solo se agrega (DA-48, DA-51). `usuario_nombre` guarda el
/// nombre de quien la anuló en ese momento, para mostrarlo aunque el usuario
/// cambie después. `fecha` en UTC (DI-13). El índice de `venta_id` **no** es
/// único: dos equipos sin conexión pueden anular la misma venta y eso se
/// resuelve al conciliar; al leer vale la más antigua (DI-39).
@DataClassName('FilaAnulacionVenta')
@TableIndex(name: 'anulaciones_venta_tienda_idx', columns: {#tiendaId})
@TableIndex(name: 'anulaciones_venta_venta_idx', columns: {#ventaId})
class AnulacionesVenta extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get ventaId => text().references(Ventas, #id)();
  TextColumn get usuarioId => text()();
  TextColumn get usuarioNombre => text()();
  DateTimeColumn get fecha => dateTime().map(const ConversorFechaUtc())();
  TextColumn get motivo => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
