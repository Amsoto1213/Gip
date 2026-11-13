# Instalación del entorno (Windows 10/11), aislada en el proyecto

Todo lo que depende de la versión (Flutter 3.47.x, JDK 17, Android SDK, Node 26 y sus cachés) se instala dentro de `gip/.herramientas/`, que no se sube a git. No se toca el PATH ni las variables del sistema: el script `tool/entorno.ps1` activa esas herramientas solo en la terminal donde se ejecuta. Los otros proyectos del computador siguen usando sus propias versiones.

Lo único que queda instalado a nivel de computador (no depende de la versión del proyecto):

| Global | Por qué |
|---|---|
| Git for Windows | Para clonar el repo; Claude Code lo usa como shell. Cualquier versión reciente sirve |
| Claude Code | Es una herramienta, no una dependencia del proyecto |
| Docker Desktop + WSL2 | Docker es un servicio del sistema; solo hay uno por computador. Los contenedores de cada proyecto quedan separados por nombre y puerto |
| Google Chrome y VS Code | Herramientas de uso general |

Requisitos del equipo: 64 bits, 8 GB de RAM, unos 20 GB libres (las cachés dentro del proyecto ocupan más) y la virtualización activada en la BIOS.

## 1. A mano: lo global (solo si no lo tienen ya)

1. Revisar la virtualización: Administrador de tareas → Rendimiento → CPU → "Virtualización: Habilitado". Si no, activarla en la BIOS.
2. Git y Claude Code (PowerShell normal); después `claude` para iniciar sesión:
   ```powershell
   winget install --id Git.Git -e
   irm https://claude.ai/install.ps1 | iex
   ```
3. WSL2 (PowerShell **como administrador**) y reiniciar:
   ```powershell
   wsl --install
   ```
4. Docker Desktop, Chrome y VS Code (PowerShell normal):
   ```powershell
   winget install --id Docker.DockerDesktop -e
   winget install --id Google.Chrome -e
   winget install --id Microsoft.VisualStudioCode -e
   ```
5. Abrir Docker Desktop una vez, aceptar los términos y esperar *Engine running* (Settings → General → *Use the WSL 2 based engine* marcado).
6. Extensiones de VS Code:
   ```powershell
   code --install-extension Dart-Code.dart-code
   code --install-extension Dart-Code.flutter
   ```
7. Verificar en una terminal nueva: `git --version`, `claude --version`, `wsl --status`, `docker run --rm hello-world`.

## 2. Con Claude Code, dentro de la carpeta del proyecto

- **A** (quien crea el proyecto): carpeta `gip` con `gip-kit-inicial.zip` y el `.qea` dentro.
- **B y C**: la carpeta que queda al hacer `git clone` del repositorio.

En esa carpeta: `claude`, y pegan este mensaje:

```text
Instala las herramientas del proyecto GIP SOLO dentro de esta carpeta, en .herramientas/.
Tengo otros proyectos con otras versiones: NO modifiques el PATH ni variables de entorno del sistema
o del usuario, NO uses instaladores globales (winget, msi) para estas herramientas y NO uses
"flutter config" (escribe una configuración global). Antes de descargar cada cosa dime qué es y espera
mi confirmación.

1. Si tool/entorno.ps1 no existe, extráelo de gip-kit-inicial.zip (solo ese archivo).
2. Descarga los ZIP portables y descomprímelos así:
   - Flutter 3.47.x stable (el último parche 3.47; NO 3.50), zip de Windows del archivo de versiones del
     SDK en docs.flutter.dev -> .herramientas/flutter
   - Eclipse Temurin JDK 17, zip x64 de adoptium.net -> .herramientas/jdk-17
   - Android "Command line tools only" para Windows -> .herramientas/android-sdk/cmdline-tools/latest
     (que quede .herramientas/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat)
   - Node.js 26 LTS, zip x64 de nodejs.org -> .herramientas/node (que node.exe quede en esa carpeta)
3. Carga el entorno en tu shell con tool/entorno.ps1 (o exporta las mismas variables en Git Bash) y:
   - sdkmanager --install "platform-tools" "platforms;android-36"
   - flutter doctor --android-licenses (yo acepto las licencias)
4. Revisa que .gitignore tenga la línea .herramientas/ (si .gitignore ya existe).
5. Verifica con el entorno cargado: flutter --version (debe decir 3.47 y Dart 3.13), flutter doctor -v,
   java -version (17), adb --version, node --version (26), docker --version.
   El aviso de "Android Studio not installed" y el de "Visual Studio" se ignoran.
6. Dame la lista de lo que todavía falla y de lo que tengo que hacer yo a mano.
```

## 3. A mano, después de Claude

1. **Docker Desktop**: si es nuevo, abrirlo una vez y esperar "Engine running".
2. **Teléfono Android**: *Ajustes → Acerca del teléfono →* tocar 7 veces *Número de compilación*; luego *Opciones de desarrollador → Depuración USB*. Conectarlo y aceptar "¿Permitir depuración USB?".

## 4. Cómo se trabaja todos los días

Cada vez que abran una terminal para el GIP:

```powershell
cd ruta\a\gip
Set-ExecutionPolicy -Scope Process Bypass    # solo para esta ventana
. .\tool\entorno.ps1                         # activa Flutter 3.47, JDK 17, Android SDK y Node 26
claude                                       # Claude Code hereda el entorno
```

En VS Code no hace falta el script: `.vscode/settings.json` hace que el editor use el Flutter de `.herramientas/` y que sus terminales ya tengan el entorno cargado.

Si abren `claude` sin cargar el entorno, Claude usará el Flutter global (o ninguno). Si `flutter --version` no dice 3.47, cierren y vuelvan a cargar el script.

## 5. Verificación final (con el entorno cargado)

```powershell
flutter --version        # Flutter 3.47.x, Dart 3.13
flutter doctor           # Flutter, Android toolchain y Chrome en verde
flutter devices          # aparecen el teléfono y Chrome
java -version            # 17
node --version           # v26
npx supabase --version   # 3.1.0 (después de npm install en el repo)
docker ps                # responde sin error
```

## Notas

- **Supabase local y otros proyectos:** el GIP usa los puertos 55321–55329 y el `project_id` "gip" (configurados en `supabase/config.toml`) para no chocar con otros proyectos de Supabase que usen los puertos por defecto 54321–54329.
- **Android Studio de otros proyectos:** si tienen Android Studio instalado, Flutter puede preferir el JDK que trae Android Studio en vez del de `JAVA_HOME`. Ese JDK suele ser 17 o 21 y funciona con Flutter 3.47; si `flutter doctor -v` mostrara otro y falla la compilación, avisen.
- **Espacio:** con las cachés de pub y Gradle dentro del proyecto, `.herramientas/` llega a ocupar entre 6 y 10 GB. Es el precio de no compartir nada con los otros proyectos.
