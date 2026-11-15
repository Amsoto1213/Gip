import 'package:drift/drift.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/tablas/ventas.dart';

/// Formas de pago de cada venta (clase `FormaPago` y sus subclases) en una
/// sola tabla con columna `tipo`, como `movimientos_inventario` (DI-03,
/// DI-21): CONTADO usa `monto_recibido` y `cambio`; NEQUI, `monto` y
/// `referencia`; FIADO, `monto` (su cliente y saldo están en `fiados`, con el
/// mismo id; DI-26). Solo se agregan.
@DataClassName('FilaFormaPago')
@TableIndex(name: 'formas_pago_tienda_idx', columns: {#tiendaId})
@TableIndex(name: 'formas_pago_venta_idx', columns: {#ventaId})
class FormasPago extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get ventaId => text().references(Ventas, #id)();
  TextColumn get tipo => text()();
  TextColumn get montoRecibido =>
      text().map(const ConversorDecimal()).nullable()();
  TextColumn get cambio => text().map(const ConversorDecimal()).nullable()();
  TextColumn get monto => text().map(const ConversorDecimal()).nullable()();
  TextColumn get referencia => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
