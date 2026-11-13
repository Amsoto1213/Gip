# Versiones fijadas del GIP

Resumen para Claude Code. La matriz completa (con fuentes) está en el documento "GIP — Matriz de versiones y plataformas".
**No cambies ninguna de estas versiones** ni corras `flutter upgrade` o `flutter pub upgrade --major-versions`; un cambio es una decisión del equipo (PR + `docs/decisiones.md`).

## Dónde corre la app
- Android 8.0 o superior: `minSdk = 26`; `compileSdk` y `targetSdk` = los de Flutter (API 36).
- Web: las dos últimas versiones estables de Chrome, Edge y Firefox de escritorio (Windows). Compilación web en JavaScript (`flutter build web`), no WebAssembly.
- No soportados: Safari/iOS/macOS, Chrome en Android como web, Firefox ESR.
- Pantallas: móvil desde 360 px de ancho (diseño a 390×844); web usable desde 1024 px (diseño a 1280–1440).
- La cámara solo se usa en la app Android; en la web, solo el lector 2D.

## Herramientas
Flutter, JDK, Android SDK y Node están instalados dentro del proyecto en `.herramientas/` y se activan con `tool/entorno.ps1` (ver `docs/instalacion.md`). Supabase local usa los puertos 55321–55329.

| Herramienta | Versión |
|---|---|
| Flutter | 3.47.x (Dart 3.13). No 3.50 |
| JDK | Temurin 17 |
| Android | AGP ≥ 9.1.0, Gradle ≥ 9.3.1, Kotlin ≥ 2.4.0 (los pone flutter create) |
| Node.js | 26.x LTS |
| Supabase CLI | 3.1.0 (en package.json; usar `npx supabase`) |
| PostgreSQL | 17 (el de Supabase) |
| Git for Windows | 2.56.x |
| Docker Desktop | 4.96 o superior |

## Paquetes con versión decidida
| Paquete | Restricción |
|---|---|
| drift | ^2.35.3 |
| drift_flutter | ^0.3.1 |
| supabase_flutter | ^2.16.0 (rama 2.x; NO 3.0) |
| mobile_scanner | ^7.5.0 |

El resto de paquetes queda fijado en `pubspec.lock` (se sube al repositorio). `sqlite3.wasm` y el worker de drift en `web/` deben ser de la misma versión de drift que diga `pubspec.lock`.
