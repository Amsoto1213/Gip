# Despliegue web en Vercel y librerías del GIP

Documento de decisiones de **despliegue** y listado de las **librerías** con las que se desarrolla el GIP.
Complementa a `docs/decisiones.md` (esta es la decisión **DI-69**), a `docs/versiones.md` (versiones fijadas) y a
`docs/desplegar-web.md` (los pasos para repetir el despliegue).

Las versiones salen de `pubspec.yaml` y `pubspec.lock` (rama `main`, 2026-11-23). Si cambian, se actualiza este documento
en el mismo PR. **No se cambian versiones** sin una decisión del equipo (`docs/versiones.md`).

## 1. Qué se despliega y dónde

| Parte | Dónde corre | Cómo se publica | Se ve en |
|---|---|---|---|
| Web (`flutter build web`) | **Vercel** | Push a `main` (producción) y a cualquier rama o PR (vista previa) | `gip-virid.vercel.app` |
| Android (APK) | Teléfono del usuario | Workflow `apk.yml` de GitHub Actions: pre-release `apk-dev` en GitHub | `https://github.com/<dueño>/gip/releases/tag/apk-dev` |
| Base de datos y Auth | **Supabase** (proyecto de pruebas en la nube) | Migraciones de `supabase/migrations/` | Panel de Supabase |

```
GitHub (main) ──push──▶ Vercel: tool/vercel_build.sh ──▶ build/web ──▶ gip-virid.vercel.app
                         ├─ instala Flutter 3.47.x
                         ├─ pub get + build_runner (código de drift)
                         └─ flutter build web --release --dart-define-from-file=.env.json
                                                   ▲
                       SUPABASE_URL y SUPABASE_ANON_KEY (variables de Vercel)

El navegador abre la web ──▶ guarda los datos en SQLite local (sqlite3.wasm) ──▶ sincroniza con Supabase
```

## 2. Decisiones de despliegue (DI-69)

| Inciso | Decisión | Motivo | Alternativa que no se tomó |
|---|---|---|---|
| (a) | La **web se publica en Vercel**. El APK sigue saliendo por GitHub Releases. | Vercel ya lo conoce y lo ha usado quien despliega; da HTTPS y una URL pública sin administrar servidores; cada PR genera su vista previa. | Otro hosting estático. No se comparó a fondo: pesó la experiencia previa con Vercel. |
| (b) | **Integración con Git**: push a `main` = producción; otras ramas y PR = vista previa. | Cero pasos manuales: el que fusiona un PR publica. | Subir `build/web` a mano con la CLI de Vercel. |
| (c) | **El build corre en Vercel** con `tool/vercel_build.sh`, que instala Flutter (Vercel no lo trae). | No necesita tokens ni secretos de Vercel en GitHub Actions; todo queda en el repo (`vercel.json` y el script). | Compilar en GitHub Actions y subir lo ya compilado a Vercel: sería más rápido, pero pide un token de Vercel guardado como secreto. |
| (d) | **Flutter `3.47.9`** por defecto, cambiable con la variable `FLUTTER_VERSION` en Vercel. | Misma versión menor que fija `docs/versiones.md`. Un tag exacto evita que un parche nuevo cambie el build sin avisar. | Dejar `stable` o `3.47.x` flotante, como hacen `ci.yml` y `apk.yml`. |
| (e) | Las claves de Supabase van como **variables de entorno de Vercel**. El script arma un `.env.json` temporal, compila con `--dart-define-from-file` y lo borra. | Mismo mecanismo de DI-04 y del APK; las claves no entran a git. | Dejar las claves en el código o en un `.env.json` versionado. |
| (f) | **`vercel.json`**: sin framework, instalación vacía, salida `build/web`, `rewrites` a `index.html`, `no-cache` en los archivos de arranque de Flutter y `application/wasm` para `sqlite3.wasm`. | El repo tiene `package.json` (la Supabase CLI): sin sobrescribir la instalación, Vercel haría un `npm install` que el build no usa. `no-cache` evita que un navegador siga con una versión vieja; las URL usan `#`, así que el `rewrite` es solo respaldo. | Elegir un framework de la lista de Vercel: Flutter no está en ella. |
| (g) | **Protección de despliegues de Vercel sin tocar**: `all_except_custom_domains`. | Es la que el equipo de Vercel aplica por defecto al crear el proyecto. Mientras la app use el Supabase de pruebas, no hay motivo para abrirla. | Desactivarla o conectar un dominio propio. Es una decisión pendiente del equipo (ver sección 5). |
| (h) | La web usa el **Supabase de pruebas en la nube**, sin RLS, y con registros abiertos y sin confirmación de correo. | CLAUDE.md: la seguridad no se implementa, salvo el inicio de sesión. CUS-15 crea la cuenta del empleado con `signUp`, y eso exige `enable_signup = true` y `enable_confirmations = false` (`CuentaAccesoSupabase`). | Un Supabase aparte para producción: queda para cuando haya tiendas reales. |

### Qué sale del último build observado

- Máquina de build de Vercel: 2 núcleos, 8 GB, región Washington D.C. (`iad1`).
- Tiempo total: unos 4 min 19 s. `build_runner`: 76 s. Compilación web: 115 s.
- Sin caché entre builds: cada uno baja Flutter y el SDK de Dart (unos 228 MB).
- Avisos que no impiden publicar: el análisis de compatibilidad con WebAssembly (la web se compila a JavaScript, como pide `docs/versiones.md`) y que `build_runner` ya no usa `--delete-conflicting-outputs`.

### Lo que hay que cuidar

- La **anon key de Supabase queda dentro del JavaScript publicado**. Es normal con la anon key, pero **nunca** se pone la `service_role`.
- Cambiar `SUPABASE_URL` o `SUPABASE_ANON_KEY` en Vercel **no actualiza** lo ya publicado: hay que volver a desplegar.
- `web/sqlite3.wasm` y `web/drift_worker.js` se publican con la app y deben ser de la misma versión de drift que diga `pubspec.lock` (`web/LEEME-drift.md`).
- Navegadores soportados: las dos últimas versiones de Chrome, Edge y Firefox de escritorio. Safari e iOS no (`docs/versiones.md`).
- El CI (`ci.yml`) también compila la web, sin claves de Supabase: sirve para detectar que el build no se rompe, no para publicar.

## 3. Librerías de la app (Dart y Flutter)

La columna "Versión" es la que resuelve `pubspec.lock`; "Restricción" es la de `pubspec.yaml`. Las capas son las de
`CLAUDE.md`: `business/` es Dart puro y solo puede usar `decimal`, `uuid`, `meta` y `collection`; el resto vive en `data/`,
`presentation/` y `composition_root/`.

### Base

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| Flutter (SDK) | 3.47.x (Dart 3.13.7 o superior) | `sdk: ^3.13.7` | Una sola base de código para Android 8.0+ y web | Todo el proyecto |
| `flutter_localizations` (SDK) | del SDK | SDK | Textos de Material en español (el selector de fechas de "Ventas de hoy" falla sin esto) | `presentation/comun/idioma_gip.dart` |
| `intl` | 0.20.3 | `^0.20.3` | No se importa directamente: lo exige `flutter_localizations` | Dependencia indirecta |
| `cupertino_icons` | 1.0.9 | `^1.0.8` | Viene de `flutter create`. No se usa en el código; la fuente se reduce a 1,4 KB al compilar | — |

### Datos locales (funciona sin internet)

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| `drift` | 2.35.4 | `^2.35.3` | Base SQLite tipada: tablas por módulo, consultas, transacciones de `IUnidadTrabajo` y la cola de sincronización | `data/local/`, `data/repositorios/` |
| `drift_flutter` | 0.3.1 | `^0.3.1` | Abre la base: SQLite nativo en Android, y `sqlite3.wasm` con un worker en la web | `data/local/base_local_drift.dart` |
| `shared_preferences` | 2.5.6 | `^2.5.6` | Guarda la sesión local del usuario activo para entrar sin internet | `data/local/sesion_local_preferencias.dart` |
| `sqlite3` | 3.5.2 | indirecta (por drift) | El motor SQLite. En la web se publica como `web/sqlite3.wasm` | `web/` |

### Servidor y sincronización

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| `supabase_flutter` | 2.18.3 | `^2.16.0` (rama 2.x, **no 3.0**) | Inicio de sesión con Supabase Auth y lectura y escritura de tablas al sincronizar | `data/service_agents/`, `composition_root/` |
| `connectivity_plus` | 7.3.2 | `^7.3.2` | Detecta que volvió la conexión para disparar la sincronización | `presentation/comun/disparador_sincronizacion.dart` |

### Estado y navegación (MVVM)

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| `provider` | 6.1.5+1 | `^6.1.5+1` | Entrega los ViewModels (`ChangeNotifier`) a las vistas (DI-01) | `presentation/` |
| `go_router` | 18.1.4 | `^18.1.4` | Rutas y navegación, con las subsecciones del menú en `rutas_<seccion>.dart` (DI-01) | `presentation/comun/router.dart` y `rutas_*.dart` |

### Reglas del dominio

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| `decimal` | 3.2.6 | `^3.2.6` | Dinero y cantidades. Nunca `double` (DI-02) | `business/`, `data/`, `presentation/` |
| `uuid` | 4.6.0 | `^4.6.0` | IDs UUID v4 generados en el dispositivo (DA-43) | `business/componentes/` |
| `collection` | 1.19.1 | `^1.19.1` | Utilidades de colecciones | `data/repositorios/` |

### Dispositivo, archivos e impresión

| Paquete | Versión | Restricción | Para qué se usa | Dónde |
|---|---|---|---|---|
| `mobile_scanner` | 7.5.0 | `^7.5.0` | Lector de códigos de barras y QR (CUS-17). La cámara solo se usa en la app Android; en la web, solo el lector 2D (`docs/versiones.md`) | `presentation/comun/leer_codigo.dart` |
| `pdf` | 3.12.0 | `^3.12.0` | Arma las etiquetas de producto en PDF | `data/service_agents/impresion_etiquetas_pdf.dart` |
| `printing` | 5.14.3 | `^5.14.3` | Imprime o comparte esas etiquetas | `data/service_agents/impresion_etiquetas_pdf.dart` |
| `csv` | 8.0.0 | `^8.0.0` | Exporta datos del negocio a CSV (CUS-16) | `data/helpers/exportador_csv_excel.dart` |
| `excel` | 4.0.6 | `^4.0.6` | Exporta a Excel (CUS-16) | `data/helpers/exportador_csv_excel.dart` |
| `share_plus` | 13.3.1 | `^13.3.1` | Comparte el archivo exportado | `data/helpers/exportador_csv_excel.dart` |

### Desarrollo y pruebas (no van en la app publicada)

| Paquete | Versión | Restricción | Para qué se usa |
|---|---|---|---|
| `flutter_test` (SDK) | del SDK | SDK | Pruebas unitarias y de widgets |
| `mocktail` | 1.0.5 | `^1.0.5` | Dobles de prueba en `test/` |
| `flutter_lints` | 6.0.0 | `^6.0.0` | Reglas de `flutter analyze` (`analysis_options.yaml`) |
| `drift_dev` | 2.35.3 | `^2.35.3` | Genera el código de drift |
| `build_runner` | 2.17.1 | `^2.17.1` | Ejecuta los generadores. Corre en el CI y en el build de Vercel |

### Fuentes y recursos

Archivo (ExtraBold) e Inter (400, 500, 600 y 700), de Google Fonts con licencia OFL, empaquetadas en `assets/fonts/`.
No se usa el paquete `google_fonts`: así las letras cargan sin internet.

## 4. Herramientas fuera de Dart

| Herramienta | Versión | Para qué |
|---|---|---|
| Supabase CLI | 3.1.0 (`package.json`; se usa con `npx supabase`) | Backend local, migraciones y `db reset` |
| Node.js | 26.x LTS | Corre la Supabase CLI |
| Docker Desktop | 4.96 o superior | Supabase local |
| PostgreSQL | 17 (el de Supabase) | Base del servidor |
| JDK / Android SDK | Temurin 17 / API 36 (`minSdk = 26`) | Compilar el APK |
| GitHub Actions | `actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/setup-java@v4`, `actions/upload-artifact@v4`, `supabase/setup-cli@v3` | CI (`ci.yml`) y APK de prueba (`apk.yml`) |
| Vercel | CLI 66.2 (la trae el build) | Publicar la web |

## 5. Pendientes y decisiones abiertas

- **Protección de Vercel**: hoy sigue `all_except_custom_domains`; solo los dominios propios están exentos. El equipo debe
  decidir si se desactiva, o si se conecta un dominio propio, antes de compartir la web con tenderos. Desactivarla deja la
  app abierta a cualquiera con el enlace.
- **Sin caché de Flutter** entre builds de Vercel: cada publicación tarda unos 4 minutos. Si molesta, la alternativa es la
  de DI-69 (c): compilar en GitHub Actions.
- **Versión de Flutter**: Vercel usa `3.47.9` y el CI `3.47.x`. Conviene fijar la misma en los tres lugares cuando el equipo
  confirme el parche que usa en local.
- **`cupertino_icons` e `intl`** no se importan en el código. No se tocan aquí porque `pubspec.yaml` es un archivo compartido.
- **Supabase de producción** separado del de pruebas, y RLS: fuera del alcance del curso.
