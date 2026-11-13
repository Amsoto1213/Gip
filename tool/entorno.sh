#!/usr/bin/env bash
# Activa las herramientas del GIP SOLO en esta terminal (Linux). No cambia nada global.
# Todo vive en .herramientas/ dentro del proyecto (Flutter, JDK, Android SDK, Node y sus cachés).
#
# Uso, desde la raíz del repositorio (gip):
#   source tool/entorno.sh
#   claude            # o: code .   o: flutter run ...
#
# Al cerrar la terminal todo vuelve a como estaba.

if [ -n "${BASH_SOURCE[0]}" ]; then _gip_script="${BASH_SOURCE[0]}"; else _gip_script="$0"; fi
GIP_RAIZ="$(cd "$(dirname "$_gip_script")/.." && pwd)"
H="$GIP_RAIZ/.herramientas"

if [ ! -d "$H" ]; then
  echo "No existe $H. Primero instalen las herramientas (docs/instalacion-linux.md)." >&2
  return 1 2>/dev/null || exit 1
fi

export GIP_HERRAMIENTAS="$H"
export JAVA_HOME="$H/jdk-17"
export ANDROID_HOME="$H/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PUB_CACHE="$H/pub-cache"
export GRADLE_USER_HOME="$H/gradle"
export FLUTTER_ROOT="$H/flutter"
# Configuración de Flutter propia del proyecto. Flutter guarda la suya en $XDG_CONFIG_HOME/flutter
# (~/.config/flutter) y, si otro proyecto le fijó "android-sdk" ahí, esa ruta gana sobre ANDROID_HOME.
# Solo flutter y dart ven esta carpeta; el resto de programas de la terminal sigue con su configuración.
export GIP_FLUTTER_CONFIG="$H/config"
mkdir -p "$GIP_FLUTTER_CONFIG"
flutter() { XDG_CONFIG_HOME="$GIP_FLUTTER_CONFIG" command flutter "$@"; }
dart()    { XDG_CONFIG_HOME="$GIP_FLUTTER_CONFIG" command dart "$@"; }
export -f flutter dart
# Si no hay Google Chrome, Flutter puede usar Chromium:
if ! command -v google-chrome >/dev/null 2>&1 && command -v chromium >/dev/null 2>&1; then
  export CHROME_EXECUTABLE="$(command -v chromium)"
fi

# Las rutas del proyecto van primero: ganan sobre cualquier Flutter, Java o Node global.
export PATH="$H/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$H/node/bin:$GIP_RAIZ/node_modules/.bin:$PATH"

echo "Entorno GIP activo en esta terminal ($H)"
echo "  flutter: $(flutter --version 2>/dev/null | head -1)"
echo "  java:    $(java -version 2>&1 | head -1)"
echo "  node:    $(node --version 2>/dev/null)"
unset _gip_script
