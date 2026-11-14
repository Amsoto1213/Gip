import 'package:drift/drift.dart';

/// Caja del día de cada tienda (clase `Caja`). El id no es un UUID: se forma
/// con la tienda y la fecha (`<tienda_id>_AAAA-MM-DD`) para que dos
/// dispositivos sin conexión abran la misma caja (DA-62, DI-21). `fecha` es el
/// día local como texto "AAAA-MM-DD", no un instante (DI-21). El saldo no se
/// guarda: se calcula de los movimientos (DA-48). Las columnas del cierre
/// llegan con CUS-14.
@DataClassName('FilaCaja')
@TableIndex(name: 'cajas_tienda_idx', columns: {#tiendaId})
class Cajas extends Table {
  TextColumn get id => text()();
  TextColumn get tiendaId => text()();
  TextColumn get fecha => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
