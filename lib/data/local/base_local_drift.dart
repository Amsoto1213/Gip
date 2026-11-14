import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/cola_pendientes.dart';
import 'package:gip/data/local/tablas/items_inventario.dart';
import 'package:gip/data/local/tablas/movimientos_inventario.dart';
import 'package:gip/data/local/tablas/productos.dart';

part 'base_local_drift.g.dart';

/// Base local SQLite del GIP (drift). Cada módulo agrega sus tablas en
/// `data/local/tablas/` y las registra aquí.
@DriftDatabase(
  tables: [ColaPendientes, Productos, ItemsInventario, MovimientosInventario],
)
class BaseLocalDrift extends _$BaseLocalDrift {
  /// Para las pruebas: recibe la conexión (por ejemplo, una base en memoria).
  BaseLocalDrift(super.e);

  /// Abre la base `gip` del dispositivo. En la web usa `web/sqlite3.wasm` y
  /// `web/drift_worker.js` (ver `web/LEEME-drift.md`).
  BaseLocalDrift.abrir()
    : super(
        driftDatabase(
          name: 'gip',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  /// 1: cola_pendientes. 2: productos e items_inventario (CUS-18).
  /// 3: movimientos_inventario (CUS-01).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, desde, hasta) async {
      if (desde < 2) {
        await m.createTable(productos);
        await m.createIndex(productosTiendaCodigoIdx);
        await m.createIndex(productosTiendaNombreIdx);
        await m.createTable(itemsInventario);
        await m.createIndex(itemsInventarioTiendaIdx);
      }
      if (desde < 3) {
        await m.createTable(movimientosInventario);
        await m.createIndex(movimientosInventarioTiendaIdx);
        await m.createIndex(movimientosInventarioItemTipoFechaIdx);
      }
    },
  );
}
