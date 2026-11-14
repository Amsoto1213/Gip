import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gip/data/local/conversores/conversor_decimal.dart';
import 'package:gip/data/local/conversores/conversor_fecha_utc.dart';
import 'package:gip/data/local/tablas/cajas.dart';
import 'package:gip/data/local/tablas/cola_pendientes.dart';
import 'package:gip/data/local/tablas/formas_pago.dart';
import 'package:gip/data/local/tablas/items_inventario.dart';
import 'package:gip/data/local/tablas/movimientos_caja.dart';
import 'package:gip/data/local/tablas/movimientos_inventario.dart';
import 'package:gip/data/local/tablas/productos.dart';
import 'package:gip/data/local/tablas/ventas.dart';

part 'base_local_drift.g.dart';

/// Base local SQLite del GIP (drift). Cada módulo agrega sus tablas en
/// `data/local/tablas/` y las registra aquí.
@DriftDatabase(
  tables: [
    ColaPendientes,
    Productos,
    ItemsInventario,
    MovimientosInventario,
    Cajas,
    MovimientosCaja,
    Ventas,
    FormasPago,
  ],
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
  /// 3: movimientos_inventario (CUS-01). 4: cajas, movimientos_caja, ventas,
  /// formas_pago y las columnas de SALIDA_VENTA (CUS-02).
  @override
  int get schemaVersion => 4;

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
      if (desde < 4) {
        await m.createTable(cajas);
        await m.createIndex(cajasTiendaIdx);
        await m.createTable(movimientosCaja);
        await m.createIndex(movimientosCajaTiendaIdx);
        await m.createIndex(movimientosCajaCajaIdx);
        await m.createTable(ventas);
        await m.createIndex(ventasTiendaFechaIdx);
        await m.createTable(formasPago);
        await m.createIndex(formasPagoTiendaIdx);
        await m.createIndex(formasPagoVentaIdx);
        // Si la tabla se acaba de crear en el paso 3, ya trae las columnas.
        if (desde >= 3) {
          await m.addColumn(
            movimientosInventario,
            movimientosInventario.ventaId,
          );
          await m.addColumn(
            movimientosInventario,
            movimientosInventario.precioUnitario,
          );
        }
      }
    },
  );
}
