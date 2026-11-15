import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/clientes.dart';
import 'package:gip/data/local/tablas/formas_pago.dart';

/// Fiados (clase `Fiado`). El fiado es una forma de pago: `id` es el mismo de
/// su fila FIADO en `formas_pago`, que lo une a su venta (DI-26). Guarda el
/// saldo y el estado (PENDIENTE, SALDADO, ANULADO) que actualizan los abonos
/// (CUS-08) y la anulación (CUS-20). `fecha_inicio` en UTC (DI-13).
@DataClassName('FilaFiado')
@TableIndex(name: 'fiados_tienda_idx', columns: {#tiendaId})
@TableIndex(name: 'fiados_cliente_idx', columns: {#clienteId})
class Fiados extends Table {
  TextColumn get id => text().references(FormasPago, #id)();
  TextColumn get tiendaId => text()();
  TextColumn get clienteId => text().references(Clientes, #id)();
  TextColumn get montoInicial => text().map(const ConversorDecimal())();
  TextColumn get saldoPendiente => text().map(const ConversorDecimal())();
  TextColumn get estado => text()();
  DateTimeColumn get fechaInicio => dateTime().map(const ConversorFechaUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
