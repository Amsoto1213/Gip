# Activa las herramientas del GIP SOLO en esta terminal. No cambia nada global del computador.
# Todo vive en .herramientas/ dentro del proyecto (Flutter, JDK, Android SDK, Node y sus cachés).
#
# Uso, desde la raíz del repositorio (gip):
#   Set-ExecutionPolicy -Scope Process Bypass     # permite scripts solo en esta ventana
#   . .\tool\entorno.ps1                          # ojo al punto y espacio del inicio
#   claude                                        # o: code .   o: flutter run ...
#
# Al cerrar la terminal todo vuelve a como estaba: sus otros proyectos no se ven afectados.

$raiz = Split-Path -Parent $PSScriptRoot
$h = Join-Path $raiz '.herramientas'

if (-not (Test-Path $h)) {
    Write-Warning "No existe $h. Primero instalen las herramientas (docs/instalacion.md)."
    return
}

$env:GIP_HERRAMIENTAS = $h
$env:JAVA_HOME        = Join-Path $h 'jdk-17'
$env:ANDROID_HOME     = Join-Path $h 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PUB_CACHE        = Join-Path $h 'pub-cache'   # paquetes de Dart separados de otros proyectos
$env:GRADLE_USER_HOME = Join-Path $h 'gradle'      # caché de Gradle separada de otros proyectos
$env:FLUTTER_ROOT     = Join-Path $h 'flutter'

$rutas = @(
    (Join-Path $h 'flutter\bin'),
    (Join-Path $env:JAVA_HOME 'bin'),
    (Join-Path $env:ANDROID_HOME 'platform-tools'),
    (Join-Path $env:ANDROID_HOME 'cmdline-tools\latest\bin'),
    (Join-Path $h 'node'),
    (Join-Path $raiz 'node_modules\.bin')
)
# Las rutas del proyecto van primero: ganan sobre cualquier Flutter, Java o Node global.
$env:Path = ($rutas -join ';') + ';' + $env:Path

Write-Host "Entorno GIP activo en esta terminal ($h)" -ForegroundColor Green
foreach ($c in @('flutter --version', 'java -version', 'node --version')) {
    try { $s = (Invoke-Expression "$c 2>&1" | Select-Object -First 1); Write-Host "  $c -> $s" }
    catch { Write-Host "  $c -> no encontrado" -ForegroundColor Yellow }
}
