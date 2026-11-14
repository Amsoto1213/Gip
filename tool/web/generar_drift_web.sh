#!/usr/bin/env bash
# Genera los dos archivos que drift necesita en la web, con las versiones de pubspec.lock:
#   web/drift_worker.js  compilado aquí con el drift y el sqlite3 del lock
#   web/sqlite3.wasm     descargado del release de sqlite3.dart de la versión del lock
# Correr después de cambiar drift o sqlite3 en pubspec.lock (ver web/LEEME-drift.md).
set -euo pipefail
cd "$(dirname "$0")/../.."

version() { awk -v p="  $1:" '$0==p{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }
drift=$(version drift)
sqlite3=$(version sqlite3)
echo "drift $drift · sqlite3 $sqlite3"

dart compile js -O4 -o web/drift_worker.js tool/web/drift_worker.dart
rm -f web/drift_worker.js.deps web/drift_worker.js.map

curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite3/sqlite3.wasm"

sha256sum web/drift_worker.js web/sqlite3.wasm
