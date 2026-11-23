# Desplegar la web en Vercel

La web (`flutter build web`) se publica en Vercel desde el repositorio de GitHub. Vercel no trae Flutter, así que
`tool/vercel_build.sh` lo instala en cada build (versión 3.47.x, ver `docs/versiones.md`) y compila a `build/web`.
La configuración está en `vercel.json`. Por qué se eligió así, y la lista de librerías del proyecto, en
`docs/decisiones-despliegue.md` (DI-69).

## Primera vez

1. En [vercel.com/new](https://vercel.com/new) importar el repositorio `Amsoto1213/Gip`.
2. **Framework Preset**: `Other`. No cambiar Build Command, Install Command ni Output Directory: salen de `vercel.json`.
3. En **Environment Variables** (Production y Preview) agregar las mismas claves del `.env.json`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. Deploy. El primer build tarda unos 5 a 8 minutos (baja Flutter y compila); los siguientes igual, porque Vercel no guarda el SDK.

Cada push a `main` publica en producción y cada rama o PR genera una URL de vista previa.

## Cosas a tener en cuenta

- **Versión de Flutter**: por defecto `3.47.9`. Para fijar otra 3.47.x, crear la variable `FLUTTER_VERSION` en Vercel.
  Cambiar a otra versión menor es una decisión del equipo (`docs/versiones.md`).
- **Supabase**: la URL y la anon key terminan dentro del JavaScript publicado (es normal con la anon key). No pongas
  ahí la `service_role`. Las tablas no tienen RLS (ver `CLAUDE.md`): usar solo el proyecto de pruebas.
- **Drift en web**: `web/sqlite3.wasm` y `web/drift_worker.js` se publican junto con la app; `vercel.json` fuerza el
  tipo `application/wasm`.
- **Rutas**: la app usa URLs con `#` (sin `usePathUrlStrategy`), por eso recargar una pantalla funciona; la regla de
  `rewrites` queda como respaldo si se cambia la estrategia de URL.
- Si el build falla con `Falta SUPABASE_URL`, faltan las variables del paso 3.
