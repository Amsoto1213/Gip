import 'package:drift/wasm.dart';

/// Worker de drift para la web. Se compila a `web/drift_worker.js` con
/// `bash tool/web/generar_drift_web.sh` (ver `web/LEEME-drift.md`).
void main() => WasmDatabase.workerMainForOpen();
