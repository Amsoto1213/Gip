# Instalación del entorno en Linux Mint (22.x, base Ubuntu 24.04), aislada en el proyecto

Igual que en Windows (`docs/instalacion.md`): Flutter 3.47.x, JDK 17, Android SDK y Node 26 quedan en `gip/.herramientas/` y se activan con `source tool/entorno.sh` solo en la terminal donde se ejecuta. Globales quedan Git, Claude Code, Docker Engine, Chrome y VS Code.

## 1. Global, una sola vez (omitan lo que ya tengan)

```bash
# Paquetes base + reglas udev para que adb vea el teléfono
sudo apt update
sudo apt install -y git curl wget unzip xz-utils zip libglu1-mesa android-sdk-platform-tools-common
sudo usermod -aG plugdev "$USER"

# Google Chrome (Flutter web lo usa para depurar)
wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/chrome.deb

# Docker Engine (si no lo tienen ya por otro proyecto)
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash
```

Cierren sesión y vuelvan a entrar (para que apliquen los grupos `docker` y `plugdev`). Verifiquen: `docker run --rm hello-world`.

## 2. Herramientas del proyecto, con Claude Code

En la carpeta del proyecto (`gip` con el kit y el `.qea`, o la carpeta clonada): `claude` y pegar:

```text
Estoy en Linux Mint (x86_64). Instala las herramientas del proyecto GIP SOLO dentro de esta carpeta,
en .herramientas/. Tengo otros proyectos con otras versiones: NO uses apt, snap ni sudo para estas
herramientas, NO modifiques ~/.bashrc, ~/.profile ni variables globales y NO uses "flutter config".
Antes de descargar cada cosa dime qué es y espera mi confirmación.

1. Si tool/entorno.sh no existe, extráelo de gip-kit-inicial.zip (solo ese archivo).
2. Descarga y descomprime los archivos portables de Linux x64:
   - Flutter 3.47.x stable (el último parche 3.47; NO 3.50), tar.xz del archivo de versiones del SDK
     en docs.flutter.dev -> .herramientas/flutter
   - Eclipse Temurin JDK 17, tar.gz de adoptium.net -> .herramientas/jdk-17
   - Android "Command line tools only" para Linux -> .herramientas/android-sdk/cmdline-tools/latest
     (que quede .herramientas/android-sdk/cmdline-tools/latest/bin/sdkmanager)
   - Node.js 26 LTS, tar.xz linux-x64 de nodejs.org -> .herramientas/node (que quede node/bin/node)
3. Con "source tool/entorno.sh" cargado en el mismo comando:
   - sdkmanager --install "platform-tools" "platforms;android-36"
   - flutter doctor --android-licenses (yo acepto las licencias)
4. Revisa que .gitignore tenga la línea .herramientas/ (si .gitignore ya existe).
5. Verifica con el entorno cargado: flutter --version (3.47 y Dart 3.13), flutter doctor -v, java -version (17),
   adb devices, node --version (26), docker --version.
   Los avisos de "Android Studio not installed" y de la cadena de Linux desktop se ignoran.
6. Dame la lista de lo que todavía falla y de lo que tengo que hacer yo a mano.
```

## 2b. A mano después de Claude: SDK de Android y licencias

Claude no acepta licencias por ustedes. Con el entorno cargado:

```bash
source tool/entorno.sh
adb kill-server 2>/dev/null                       # por si quedó corriendo el adb de otro proyecto
sdkmanager --sdk_root="$ANDROID_HOME" --install "platform-tools" "platforms;android-36"
sdkmanager --sdk_root="$ANDROID_HOME" --licenses  # leer y aceptar con y
flutter doctor -v                                 # "Android SDK at .../gip/.herramientas/android-sdk"
which adb                                         # debe ser .../gip/.herramientas/android-sdk/platform-tools/adb
```

Si tienen otro proyecto Flutter que fijó `android-sdk` con `flutter config`, `tool/entorno.sh` le da al GIP su propia configuración de Flutter (en `.herramientas/config`), así que esa ruta global no se usa aquí ni se modifica.

## 3. Día a día

```bash
cd ~/ruta/a/gip
source tool/entorno.sh
claude
```

En VS Code no hace falta: `.vscode/settings.json` ya carga el entorno en las terminales del editor.

## Notas

- Teléfono: activar *Depuración USB*, conectarlo y aceptar el aviso en el teléfono. `adb devices` debe mostrarlo como `device` (si dice `no permissions`, falta cerrar sesión tras agregar el grupo `plugdev`).
- Supabase local del GIP usa los puertos 55321–55329, como en Windows.
- `.gitattributes` fija los finales de línea: los `.sh` siempre en LF y los `.ps1` en CRLF, para que el repositorio funcione igual desde Windows y Linux.
