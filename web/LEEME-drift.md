# Archivos de drift para la web

`BaseLocalDrift.abrir()` (en `lib/data/local/base_local_drift.dart`) los carga en el navegador:

| Archivo | Versión | De dónde sale |
|---|---|---|
| `drift_worker.js` | drift 2.35.4 + sqlite3 3.5.2 | Compilado de `tool/web/drift_worker.dart` con los paquetes de `pubspec.lock` |
| `sqlite3.wasm` | sqlite3 3.5.2 (SQLite 3.53.4) | Release `sqlite3-3.5.2` de [simolus3/sqlite3.dart](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-3.5.2) |

El worker se compila aquí y no se baja del release de drift. Ese release trae un `drift_worker.js` y un `sqlite3.wasm`
hechos con un paquete `sqlite3` más nuevo que el de nuestro lock (su wasm es SQLite 3.54.1). Compilarlo aquí hace que
la app, el worker y el wasm usen exactamente las mismas versiones.

## Si cambia drift o sqlite3 en `pubspec.lock`

**Hay que reemplazar estos dos archivos con las versiones nuevas**, en el mismo PR que cambia el lock:

```bash
bash tool/web/generar_drift_web.sh
```

El script lee las versiones de `pubspec.lock`, compila `drift_worker.js`, baja `sqlite3.wasm` y muestra sus sha256.
Después actualiza la tabla de arriba y prueba con `flutter run -d chrome`.
