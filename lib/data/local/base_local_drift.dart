import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/cola_pendientes.dart';

part 'base_local_drift.g.dart';

/// Base local SQLite del GIP (drift). Cada módulo agrega sus tablas en
/// `data/local/tablas/` y las registra aquí.
@DriftDatabase(tables: [ColaPendientes])
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

  @override
  int get schemaVersion => 1;
}
