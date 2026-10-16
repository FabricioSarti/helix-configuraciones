<#
.SYNOPSIS
    Configura Helix con language servers para Java (Spring Boot) y Angular en Windows.

.DESCRIPTION
    Automatiza lo que SE PUEDE automatizar del setup descrito en HELIX-SETUP.md:
      - Ajusta las rutas de los .bat y del languages.toml a la carpeta base real.
      - Copia languages.toml a %APPDATA%\helix.
      - Instala typescript-language-server + typescript global (versiones Node-20-compatibles).
      - Instala el Angular Language Server local en cada proyecto Angular indicado (--no-save).
      - Corre ngcc una vez por proyecto Angular.
      - Verifica con `hx --health`.

    NO descarga JDKs, Maven, Node ni JDTLS: esos binarios se copian con la carpeta java-configs.
    El script es idempotente: se puede correr varias veces.

.PARAMETER BaseDir
    Carpeta base portable. Default: la carpeta donde está este script.

.PARAMETER AngularProjects
    Rutas de proyectos Angular. Para cada uno se detecta su versión de Angular y se instala
    el LS correspondiente + ngcc. Opcional.

.EXAMPLE
    .\setup-helix.ps1

.EXAMPLE
    .\setup-helix.ps1 -AngularProjects "D:\proj\frontend-a","D:\proj\frontend-b"
#>

param(
    [string]$BaseDir = $PSScriptRoot,
    [string[]]$AngularProjects = @()
)

$ErrorActionPreference = "Stop"
function Info($m)  { Write-Host "[INFO] $m"  -ForegroundColor Cyan }
function Ok($m)    { Write-Host "[ OK ] $m"  -ForegroundColor Green }
function Warn($m)  { Write-Host "[WARN] $m"  -ForegroundColor Yellow }
function Fail($m)  { Write-Host "[FAIL] $m"  -ForegroundColor Red }

Info "Carpeta base: $BaseDir"

# --- 1. Validar que estan los binarios portables requeridos ---
$required = @{
    "JDK 21"       = "$BaseDir\jdk-21\bin\java.exe"
    "JDK 8"        = "$BaseDir\jdk8\bin\java.exe"
    "JDTLS"        = "$BaseDir\jdtls\plugins"
    "Maven"        = "$BaseDir\maven\bin\mvn.cmd"
    "Node 20"      = "$BaseDir\nodejs-20\node\node.exe"
    "npm-packages" = "$BaseDir\nodejs-20\npm-packages"
}
$missing = $false
foreach ($k in $required.Keys) {
    if (Test-Path $required[$k]) { Ok "$k encontrado" }
    else { Fail "$k NO encontrado en $($required[$k])"; $missing = $true }
}
if ($missing) {
    Fail "Faltan binarios portables. Copia la carpeta java-configs completa antes de correr este script."
    exit 1
}

$node = "$BaseDir\nodejs-20\node\node.exe"
$npm  = "$BaseDir\nodejs-20\node\node_modules\npm\bin\npm-cli.js"

# --- 2. Generar los 3 wrappers .bat con la ruta base correcta ---
Info "Generando wrappers .bat..."

$jdtlsBat = @"
@echo off
chcp 65001 >nul
set "JDTLS_HOME=$BaseDir\jdtls"
set "JAVA21=$BaseDir\jdk-21"
for %%f in ("%JDTLS_HOME%\plugins\org.eclipse.equinox.launcher_*.jar") do set "LAUNCHER=%%f"
set "WS=%CD::=%"
set "WS=%WS:\=_%"
"%JAVA21%\bin\java.exe" ^
  -Dfile.encoding=UTF-8 ^
  -Dstdout.encoding=UTF-8 ^
  -Dstderr.encoding=UTF-8 ^
  -Declipse.application=org.eclipse.jdt.ls.core.id1 ^
  -Dosgi.bundles.defaultStartLevel=4 ^
  -Declipse.product=org.eclipse.jdt.ls.core.product ^
  -Xmx1G ^
  --add-modules=ALL-SYSTEM ^
  --add-opens java.base/java.util=ALL-UNNAMED ^
  --add-opens java.base/java.lang=ALL-UNNAMED ^
  -jar "%LAUNCHER%" ^
  -configuration "%JDTLS_HOME%\config_win" ^
  -data "%USERPROFILE%\.jdtls-data\%WS%"
"@
Set-Content -Path "$BaseDir\jdtls.bat" -Value $jdtlsBat -Encoding ASCII
Ok "jdtls.bat generado"

$tslsBat = @"
@echo off
"$BaseDir\nodejs-20\node\node.exe" "$BaseDir\nodejs-20\npm-packages\node_modules\typescript-language-server\lib\cli.mjs" --stdio
"@
Set-Content -Path "$BaseDir\tsls.bat" -Value $tslsBat -Encoding ASCII
Ok "tsls.bat generado"

$ngserverBat = @"
@echo off
setlocal enabledelayedexpansion
set "NODE=$BaseDir\nodejs-20\node\node.exe"

set "DIR=%CD%"
:findserver
if exist "%DIR%\node_modules\@angular\language-server\index.js" (
  set "NGLS=%DIR%\node_modules\@angular\language-server\index.js"
  set "PROBE=%DIR%\node_modules"
  goto run
)
for %%I in ("%DIR%") do set "PARENT=%%~dpI"
set "PARENT=%PARENT:~0,-1%"
if "%PARENT%"=="%DIR%" goto notfound
set "DIR=%PARENT%"
goto findserver

:notfound
echo No se encontro @angular/language-server en node_modules del proyecto. 1>&2
exit /b 1

:run
"%NODE%" "%NGLS%" --stdio --tsProbeLocations "%PROBE%" --ngProbeLocations "%PROBE%"
"@
Set-Content -Path "$BaseDir\ngserver.bat" -Value $ngserverBat -Encoding ASCII
Ok "ngserver.bat generado"

# --- 3. Generar languages.toml ---
Info "Generando languages.toml..."
$esc = $BaseDir -replace '\\','\\'
$toml = @"
[language-server.jdtls]
command = "$esc\\jdtls.bat"

[language-server.jdtls.config]
java.import.maven.enabled = true
java.configuration.updateBuildConfiguration = "automatic"
java.progressReports.enabled = true
java.maven.downloadSources = true
java.configuration.maven.globalSettings = "$esc\\maven\\conf\\settings.xml"
java.configuration.maven.userSettings = "$esc\\maven\\conf\\settings.xml"

[[language-server.jdtls.config.java.configuration.runtimes]]
name = "JavaSE-1.8"
path = "$esc\\jdk8"
default = true

[[language]]
name = "java"
language-servers = ["jdtls"]
roots = ["pom.xml", "build.gradle", ".git", "mvnw"]

[language-server.typescript-language-server]
command = "$esc\\tsls.bat"

[language-server.angular]
command = "$esc\\ngserver.bat"

[[language]]
name = "typescript"
roots = ["angular.json", "package.json", "tsconfig.json", ".git"]
language-servers = ["typescript-language-server", "angular"]

[[language]]
name = "html"
roots = ["angular.json", "package.json", "tsconfig.json", ".git"]
language-servers = ["angular"]
"@
$helixCfgDir = "$env:APPDATA\helix"
if (-not (Test-Path $helixCfgDir)) { New-Item -ItemType Directory -Path $helixCfgDir -Force | Out-Null }
# backup si ya existe
$dest = "$helixCfgDir\languages.toml"
if (Test-Path $dest) {
    Copy-Item $dest "$dest.bak" -Force
    Warn "languages.toml existente respaldado como languages.toml.bak"
}
Set-Content -Path $dest -Value $toml -Encoding UTF8
Ok "languages.toml copiado a $dest"

# --- 4. Instalar typescript-language-server + typescript global ---
Info "Instalando typescript-language-server@4.3.3 + typescript@4.9.5 (global)..."
& $node $npm install -g "typescript-language-server@4.3.3" "typescript@4.9.5" 2>&1 | Select-Object -Last 3
$tsserverGlobal = "$BaseDir\nodejs-20\npm-packages\node_modules\typescript\lib\tsserver.js"
if (Test-Path $tsserverGlobal) { Ok "TypeScript backend presente" }
else { Fail "typescript no quedo junto al LS. Revisar manualmente." }

# --- 5. Por cada proyecto Angular: instalar LS local + ngcc ---
foreach ($proj in $AngularProjects) {
    if (-not (Test-Path "$proj\package.json")) { Warn "Saltando $proj (sin package.json)"; continue }
    Info "Procesando proyecto Angular: $proj"
    $pkg = Get-Content "$proj\package.json" -Raw | ConvertFrom-Json
    $ngVer = $pkg.dependencies.'@angular/core'
    if (-not $ngVer) { Warn "  No es proyecto Angular (sin @angular/core), saltando"; continue }
    # extraer major (ej "~12.2.0" -> 12, "13.3.8" -> 13)
    $major = ([regex]::Match($ngVer, '(\d+)')).Value
    Info "  Angular detectado: v$major"
    $tsReq = if ($major -le 12) { "typescript@~4.3.5" } else { "typescript@~4.6.4" }

    Push-Location $proj
    Info "  Instalando @angular/language-server@^$major (--no-save)..."
    & $node $npm install --no-save "@angular/language-server@^$major" $tsReq 2>&1 | Select-Object -Last 2
    $lsLocal = "$proj\node_modules\@angular\language-server\index.js"
    if (Test-Path $lsLocal) { Ok "  Angular LS v$major instalado" } else { Fail "  Angular LS NO se instalo" }

    Info "  Corriendo ngcc (una vez, puede tardar)..."
    $ngccMain = "$proj\node_modules\@angular\compiler-cli\ngcc\main-ngcc.js"
    if (Test-Path $ngccMain) {
        & $node $ngccMain 2>&1 | Select-Object -Last 2
        Ok "  ngcc completado"
    } else { Warn "  ngcc no encontrado (puede no ser necesario en esta version)" }
    Pop-Location
}

# --- 6. Verificacion final ---
Info "Verificando con hx --health..."
$hx = Get-ChildItem "$BaseDir" -Recurse -Filter "hx.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($hx) {
    foreach ($lang in @("java","typescript","html")) {
        Write-Host "--- hx --health $lang ---" -ForegroundColor Magenta
        & $hx.FullName --health $lang 2>&1 | Select-Object -First 4
    }
} else {
    Warn "hx.exe no encontrado bajo $BaseDir; verifica manualmente con: hx --health java"
}

Ok "Setup completado. Reinicia Helix para que tome la configuracion."
Write-Host ""
Write-Host "Recorda: lanza Helix desde la carpeta del proyecto para que los wrappers detecten el node_modules/pom.xml correcto." -ForegroundColor Yellow
