#!/usr/bin/env bash
# Compila la versión web del GIP en Vercel.
# Vercel no trae Flutter: lo baja (misma versión menor que docs/versiones.md) y compila a build/web.
#
# Variables que deben existir en el proyecto de Vercel (Settings → Environment Variables):
#   SUPABASE_URL, SUPABASE_ANON_KEY
# Opcional: FLUTTER_VERSION (por defecto 3.47.9; debe ser un tag 3.47.x de github.com/flutter/flutter).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.9}"
: "${SUPABASE_URL:?Falta SUPABASE_URL en las variables de entorno de Vercel}"
: "${SUPABASE_ANON_KEY:?Falta SUPABASE_ANON_KEY en las variables de entorno de Vercel}"

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$HOME/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo ">> Instalando Flutter $FLUTTER_VERSION"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
export CI=true                                   # Flutter no pregunta nada y avisa menos por correr como root
export FLUTTER_SUPPRESS_ANALYTICS=true

cd "$RAIZ"
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Mismo mecanismo que el APK de GitHub: las claves entran como --dart-define-from-file, nunca se suben a git.
printf '{"SUPABASE_URL":"%s","SUPABASE_ANON_KEY":"%s"}\n' "$SUPABASE_URL" "$SUPABASE_ANON_KEY" > .env.json

flutter build web --release --dart-define-from-file=.env.json
rm -f .env.json
