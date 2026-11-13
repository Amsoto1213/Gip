# GIP — Gestor de Inventario Predictivo

App para tiendas de barrio de Bolívar: ventas, surtido (inventario), fiados, caja y reportes, con alertas de reabastecimiento.
Una sola base de código **Flutter** para **Android 8.0+ (APK)** y **web**. Funciona **sin internet** y sincroniza con **Supabase** al reconectar.
Proyecto de Ingeniería de Software (Universidad de Cartagena), equipo de 3. El código, los nombres y los mensajes van en **español**.

## Fuente de verdad del diseño

El diseño está en Enterprise Architect y exportado a texto en `docs/diseno/`. **Léelo antes de implementar y no lo contradigas.**

- `docs/diseno/clases.md` — clases, atributos, operaciones y relaciones de la Business Layer.
- `docs/diseno/secuencias/CUS-XX.md` — diagrama de secuencia de cada caso de uso (el flujo que hay que implementar).
- `docs/diseno/arquitectura.md` — componentes de la arquitectura en capas.
- `docs/ui/tokens.md` y `docs/ui/mockups/` — colores, tipografía y pantallas (mockups móvil y web).
- `docs/decisiones.md` — decisiones de implementación (DI-xx) que no están en EA.
- `docs/probar-en-telefono.md` — cómo se prueba en Android sin cable (APK de GitHub y depuración inalámbrica).
- `docs/versiones.md` — versiones fijadas de Flutter, herramientas, paquetes y navegadores soportados. **No cambies versiones** ni corras `flutter upgrade`/`pub upgrade --major-versions`.

Si algo del diseño no se puede implementar tal cual, **para y pregunta**; no inventes clases ni cambies firmas por tu cuenta. Si se acuerda un cambio, se registra en `docs/decisiones.md` y luego se actualiza en EA.

## Arquitectura (obligatoria)

Capas con dependencias solo hacia abajo (DA-01, DA-38):

```
lib/
  main.dart                  Composition Root: único lugar que conoce clases concretas de data/
  composition_root/          una función de registro por módulo (registrarPagos, registrarInventario, ...)
  presentation/              MVVM: vistas (widgets sin lógica) + view_models (ChangeNotifier)
    comun/                   tema, widgets compartidos, router, indicador de sincronización, entrada del lector
    vender/ surtido/ fiados/ caja/ negocio/ acceso/
  business/
    entidades/<modulo>/      clases de dominio puras (Dart puro)
    interfaces/<modulo>/     contratos: repositorios, IUnidadTrabajo, IEstadoSincronizacion, IImpresionEtiquetas, IExportador
    componentes/<modulo>/    servicios con las reglas (ServicioVentas, ServicioInventario, ...) y estrategias
    workflow/<modulo>/       un *Coordinator por caso de uso
  data/
    local/                   base drift (BaseLocalDrift), tablas por módulo, conversores
    repositorios/<modulo>/   implementaciones drift de las interfaces de business/interfaces
    helpers/                 UnidadTrabajoDrift, ExportadorCsvExcel
    service_agents/          Sincronizador, ClienteSupabase, ImpresionEtiquetasPdf, EstadoSincronizacion
  transversal/               errores, registro (logs), configuración. No importa ninguna capa.
```

Módulos (mismos nombres en todos los paquetes): `pagos`, `gestion_inventario`, `gestion_caja`, `info_tienda`.

Reglas que verifica `tool/check_layers.sh` (corre en CI):

1. `business/` es **Dart puro**: no importa `package:flutter`, `drift`, `supabase`, ni nada de `data/` o `presentation/`. Permitidos: `decimal`, `uuid`, `meta`, `collection`, `transversal/`.
2. Dentro de business: workflow → componentes → interfaces → entidades. Nunca al revés.
3. `presentation/` solo usa `business/workflow` y `business/entidades`. Nunca `data/` ni `componentes/`.
4. `data/` implementa `business/interfaces`; no importa `presentation/`, `workflow/` ni `componentes/`.
5. Solo `main.dart` y `composition_root/` importan clases de `data/`.
6. Un módulo no depende de una clase **concreta** de otro módulo; si lo necesita, usa un servicio o interfaz como está en `clases.md`.

## Reglas del dominio que no se negocian

- **IDs**: UUID v4 generados en el dispositivo (DA-43). Nunca autoincrementales.
- **Toda tabla y toda consulta lleva `tienda_id`**: el sistema atiende varias tiendas (clase `Tienda`). Los repositorios reciben la tienda como parámetro.
- **Operaciones que tocan varios repositorios** van dentro de `IUnidadTrabajo.ejecutar(...)` (una transacción drift). Si una operación se anida, se une a la transacción externa (DA-44, DA-53).
- **Cada escritura local agrega su entrada a `cola_pendientes` en la misma transacción** (sincronización, DA-33).
- Ventas, movimientos de inventario, abonos y movimientos de caja **solo se agregan**; se anulan con un registro, nunca se borran ni se editan (RNF-15). Stock y saldos **se recalculan** a partir de los movimientos; no se sincronizan como número.
- En `Producto` y `Cliente` gana la edición más reciente (`actualizadoEn`, DA-48). Los demás choques se guardan como `ConflictoSincronizacion`.
- Dinero y cantidades usan `Decimal` (paquete `decimal`), nunca `double`. Fechas en UTC al guardar, hora local al mostrar.
- Registrar venta, entrada, fiado y consultar existencias **no pueden esperar la red** (RNF-08, RD-07).
- Mensajes al usuario en el lenguaje del tendero ("No hay suficiente existencia del producto"), tal como aparecen en los diagramas de secuencia.

## Convenciones de código

- Archivos `snake_case.dart`; clases con el nombre exacto de EA (`ServicioVentas`, `RegistrarVentaCoordinator`, `IVentaRepositorio`).
- Implementaciones de data: `<Nombre>Drift` (p. ej. `VentaRepositorioDrift implements IVentaRepositorio`).
- Errores de negocio: subclases de `ExcepcionNegocio` (en `transversal/errores/`) con el mensaje para el usuario.
- Inyección por constructor. Nada de singletons globales ni service locators.
- ViewModels: `ChangeNotifier`, uno por pantalla, llaman a **un** coordinador. Las vistas no contienen reglas.
- Tema: usa los tokens de `docs/ui/tokens.md` vía `presentation/comun/tema/`. No pongas colores sueltos en widgets.
- Áreas táctiles de 44 px o más; pantallas usables en 5" y en escritorio (RNF-19, RNF-20).

## Comandos

Las herramientas (Flutter 3.47, JDK 17, Android SDK, Node 26) están en `.herramientas/` y se activan antes de abrir Claude Code con `. .\tool\entorno.ps1` (Windows) o `source tool/entorno.sh` (Linux). Si `flutter --version` no dice 3.47, el entorno no está cargado: avisa en vez de seguir. Nunca instales herramientas globales ni uses `flutter config`.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # después de cambiar tablas drift
flutter analyze
flutter test
bash tool/check_layers.sh
flutter run -d chrome          # web
flutter run                    # Android conectado
npm install                    # instala la Supabase CLI fijada en package.json
npx supabase start             # backend local (requiere Docker)
npx supabase migration new <nombre>
npx supabase db reset          # reaplica migraciones + seed en local
```

## Flujo de trabajo

- Una rama por caso de uso: `feat/cus-02-registrar-venta`. Commits: `feat(pagos): CUS-02 confirmar venta` (Conventional Commits).
- Antes de implementar un CUS: lee su `secuencias/CUS-XX.md`, las clases involucradas en `clases.md` y su mockup; propón un plan y espera aprobación.
- Orden de implementación de un CUS: entidades → interfaces → pruebas unitarias del servicio con repositorios falsos → servicio → coordinador → repositorio drift → view model → vista.
- Toda regla de negocio nueva lleva prueba unitaria en `test/business/...`. Cálculos críticos (stock, saldo, margen, total) siempre probados (RNF-05).
- Antes de terminar: `flutter analyze`, `flutter test` y `bash tool/check_layers.sh` sin errores.
- No hagas `git push`, `supabase db push` ni cambios en `main` sin que el integrante lo pida.

## Archivos compartidos (avisar al equipo antes de tocarlos)

`pubspec.yaml`, `lib/data/local/base_local_drift.dart`, `lib/main.dart`, `lib/presentation/comun/router.dart`, `supabase/migrations/`. Agrega en tu propio archivo de módulo cuando sea posible (tablas, registro de dependencias, rutas).

## Inicio de sesión sí; el resto de la seguridad, no

Por indicación del docente, la seguridad no se implementa en este curso, **salvo el inicio de sesión**.

**Sí se hace — inicio de sesión simple:**

- Correo y contraseña con **Supabase Auth** (`signInWithPassword`). Supabase guarda la contraseña; nosotros no manejamos hashes.
- Tras iniciar sesión se busca en la tabla `usuarios` la fila con ese `correo` para saber su `tienda_id` y su `rol`. Ese es el **usuario activo** de la sesión.
- La sesión queda guardada en el dispositivo (lo hace `supabase_flutter`): las siguientes veces la app entra directo, **también sin internet**. Solo el primer inicio de sesión necesita conexión.
- Botón "Cerrar sesión" en Negocio.
- Capas: `presentation/acceso/` (vista + view model) → `IniciarSesionCoordinator` (workflow/info_tienda) → `ServicioAcceso` (componentes/info_tienda) → interfaz `IAutenticacion` (interfaces/info_tienda) ← `AutenticacionSupabase` (data/service_agents). Estas piezas no están en EA: están registradas en `docs/decisiones.md` (DI-05).
- `ServicioAcceso` usa el rol del usuario activo para mostrar u ocultar opciones de administrador (ganancia, reportes, usuarios).

**No agregues** nada de lo siguiente aunque aparezca en el ERS o en `docs/diseno/arquitectura.md` (componente "Seguridad"):

- PIN, cierre de sesión por inactividad, recuperación de contraseña, verificación de correo (RNF-11 en lo que pasa de correo y contraseña, RNF-17);
- Row Level Security, políticas o roles en PostgreSQL (RNF-12 y RNF-13 en el servidor);
- cifrado propio, `flutter_secure_storage`, auditoría más allá de lo que ya pide el diseño (p. ej. `AnulacionVenta`).

Las tablas de Supabase no tienen RLS: usar solo datos de prueba. La URL y la anon key de Supabase van en `.env.json` (no se sube a git porque cambia en cada equipo), inyectadas con `--dart-define-from-file=.env.json`.
