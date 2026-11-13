# Decisiones de implementación (DI-xx)

Decisiones tomadas al programar que no están en el modelo de EA. Las de arquitectura y diseño siguen en la bitácora DA-xx.
Formato: código, fecha, decisión, motivo, quién. Si una DI cambia el diseño, se actualiza también en EA y se regenera `docs/diseno/`.

| Código | Fecha | Decisión | Motivo | Quién |
|---|---|---|---|---|
| DI-01 | | Estado de pantalla con `ChangeNotifier` + `provider`; navegación con `go_router`. | Guía oficial de arquitectura de Flutter (MVVM, DA-67). | |
| DI-02 | | Dinero y cantidades: `Decimal` en Dart; `TEXT` en SQLite (conversor drift); `numeric(14,2)` / `numeric(12,3)` en PostgreSQL. | El diseño usa `Decimal`; evitar errores de redondeo de `double`. | |
| DI-03 | | `MovimientoInventario` y sus subclases en una sola tabla `movimientos_inventario` con columna `tipo` (ENTRADA, MERMA, AJUSTE_CONTEO, SALIDA_VENTA). | Herencia de tabla única: consultas de stock y sincronización en un solo lugar. | |
| DI-04 | | Configuración por `--dart-define-from-file=.env.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). | La URL cambia entre Supabase local y el de pruebas. | |
| DI-05 | 2026-11-12 | Seguridad fuera de alcance excepto el inicio de sesión: correo y contraseña con Supabase Auth; la fila de `usuarios` con ese correo da la tienda y el rol. Sin PIN, RLS, cierre por inactividad ni recuperación de contraseña. Clases nuevas: `IniciarSesionCoordinator`, `IAutenticacion`, `AutenticacionSupabase`; `ServicioAcceso` gana `iniciarSesion` y `cerrarSesion`. Pasarlas a EA. | Indicación del docente: la seguridad no se ve en el curso, pero el sistema debe tener login. Afecta RNF-11 a RNF-17. | Equipo |
| DI-06 | 2026-11-13 | Flutter 3.47.x (último parche de la línea 3.47, Dart 3.13) para los tres y para CI. No actualizar a 3.50 durante el proyecto. | 3.50 acaba de salir y depreca Material integrado a favor del paquete `material_ui`; 3.47 lleva tres meses de parches. | Equipo |
| DI-07 | 2026-11-13 | Plataformas: Android 8.0+ (minSdk 26) y web en las dos últimas estables de Chrome, Edge y Firefox de escritorio, compilada en JavaScript. Safari/iOS fuera. | RNF-18 y el soporte oficial de Flutter 3.47. | Equipo |
| DI-08 | 2026-11-13 | supabase_flutter ^2.16.0 (rama 2.x) y Supabase CLI 3.1.0 fijada en package.json. | supabase_flutter 3.0 acaba de salir con cambios incompatibles; la CLI fijada evita diferencias entre equipos y CI. | Equipo |
| DI-09 | 2026-11-13 | Herramientas aisladas por proyecto: Flutter, JDK 17, Android SDK y Node 26 en `.herramientas/` (portables, sin instaladores ni PATH global), activadas con `tool/entorno.ps1` o con `.vscode/settings.json`. Supabase local en puertos 55321–55329. | Los integrantes tienen otros proyectos con otras versiones. | Equipo |
| DI-10 | 2026-11-13 | Pruebas en el teléfono sin cable: APK generado por GitHub Actions (`apk.yml`) en cada push a `main` o a pedido, publicado en la pre-release `apk-dev`, firmado con una llave fija (secreto `ANDROID_DEBUG_KEYSTORE_B64`) y apuntando al Supabase de pruebas en la nube. Depuración inalámbrica como alternativa para desarrollar. | No hay cable USB disponible. | Equipo |
