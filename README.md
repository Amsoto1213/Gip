# GIP — Gestor de Inventario Predictivo

App Flutter (Android 8.0+ y web) con base local drift (SQLite) y servidor Supabase. Ver `CLAUDE.md` para arquitectura y reglas.

## Entorno

Las herramientas del proyecto (Flutter 3.47.x, JDK 17, Android SDK, Node 26) se instalan **dentro de la carpeta** en `.herramientas/`, sin tocar nada global. Ver `docs/instalacion.md`. Versiones: `docs/versiones.md`.

## Cada día

```powershell
Set-ExecutionPolicy -Scope Process Bypass
. .\tool\entorno.ps1
npm install                      # la primera vez: Supabase CLI 3.1.0
npx supabase start               # API en http://127.0.0.1:55321
flutter pub get
flutter run -d chrome --dart-define-from-file=.env.json
```

## Diseño

- `docs/diseno/` — exportado del .qea de Enterprise Architect (regenerar con `python3 tool/export_qea.py <ruta.qea> docs/diseno`).
- `docs/ui/` — tokens visuales y mapa de pantallas de los mockups.
- `docs/decisiones.md` — decisiones de implementación.
