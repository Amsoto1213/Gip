# Probar en el teléfono sin cable USB

Hay dos formas, y se complementan:

| Forma | Para qué | Velocidad |
|---|---|---|
| **APK de GitHub** (workflow `APK de prueba`) | Probar la app instalada "de verdad": sin internet, cámara, lector Bluetooth, rendimiento en gama baja | 6–10 min por build |
| **Depuración inalámbrica** (Android 11 o superior, misma red Wi-Fi) | Desarrollar con `flutter run`: hot reload y logs en la terminal, como con cable | Inmediata |

El día a día se hace en Chrome (`flutter run -d chrome`); el teléfono se usa para lo que solo existe en Android.

## Configuración única del APK (la hace A al crear el repositorio)

1. **Llave de firma fija.** Sin ella cada APK sale con otra firma y el teléfono obliga a desinstalar la app, lo que borra la base local. Con el entorno cargado:
   ```bash
   keytool -genkeypair -v -keystore debug.keystore -storepass android -alias androiddebugkey \
     -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   base64 -w0 debug.keystore     # Linux. En Windows: [Convert]::ToBase64String([IO.File]::ReadAllBytes("debug.keystore"))
   ```
   Copiar el texto y guardarlo en GitHub: *Settings → Secrets and variables → Actions → New repository secret*, nombre `ANDROID_DEBUG_KEYSTORE_B64`. Después borrar `debug.keystore` del disco (no se sube al repo).

   El workflow escribe la llave en un archivo y se la pasa a Gradle con la variable `GIP_KEYSTORE` (`android/app/build.gradle.kts`); el paso *Verificar la firma* no publica el APK si no salió con esa llave. `flutter run` en el teléfono firma con la llave de cada computador: al pasar de una instalación con `flutter run` al APK de GitHub (o al revés) hay que desinstalar la app primero.
2. **Supabase para el teléfono.** El APK no puede usar el Supabase local de nadie (127.0.0.1 es el propio teléfono). Se apunta al proyecto de pruebas en Supabase Cloud: secretos `SUPABASE_URL` y `SUPABASE_ANON_KEY`. Si aún no existe, el APK igual funciona sin conexión (la app es offline-first), pero no sincroniza.

## Instalar el APK en el teléfono

1. En el navegador del teléfono, con sesión iniciada en GitHub (el repo es privado), abrir `https://github.com/<dueño>/gip/releases/tag/apk-dev` y descargar `gip-xxxxxxx.apk`.
2. La primera vez Android pide permitir "Instalar apps desconocidas" para el navegador o el gestor de archivos: aceptar.
3. Instalar. Las siguientes veces se instala encima y se conservan los datos (por la firma fija).
4. Play Protect puede avisar que la app es desconocida: "Instalar de todas formas".

El APK se genera solo con cada merge a `main`. Para probar una rama antes del merge: *Actions → APK de prueba → Run workflow* y elegir la rama (la pre-release `apk-dev` se reemplaza con esa build).

## Depuración inalámbrica (opcional, sin cable)

Teléfono y computador en la misma red Wi-Fi, Android 11 o superior:

1. *Opciones de desarrollador → Depuración inalámbrica* → activar → *Vincular dispositivo con código de vinculación*.
2. En la terminal, con el entorno cargado: `adb pair IP:PUERTO` (los que muestra esa pantalla) e ingresar el código.
3. `adb connect IP:PUERTO` (el puerto de la pantalla principal de Depuración inalámbrica, que es otro).
4. `flutter devices` muestra el teléfono; `flutter run --dart-define-from-file=.env.json` instala con hot reload.

Para que el teléfono vea el Supabase local del computador, `.env.json` debe usar la IP del computador en la red (por ejemplo `http://192.168.1.20:55321`), no `127.0.0.1`.

## Lector de códigos

Sin cable, el lector 2D debe ser **Bluetooth en modo teclado (HID)**: se empareja desde los ajustes de Bluetooth del teléfono y escribe como un teclado. Un lector USB necesitaría un adaptador OTG.

## Minutos de GitHub Actions

En repos privados GitHub da una cuota mensual de minutos (más alta con GitHub Pro / Student Pack). Cada APK toma unos 6–10 minutos; por eso el workflow solo corre en `main` y a pedido, no en cada push de cada rama.
