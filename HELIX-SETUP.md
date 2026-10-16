# Helix LSP Setup — Java (Spring Boot) + Angular en Windows

Manual para configurar Helix con language servers para **Java 8 (Spring Boot/Maven)** y
**Angular 12/13** en Windows, con todo portable bajo una sola carpeta.

Todo asume la carpeta base: `C:\Users\<usuario>\Documents\tools-dev`.
Ajustá esa ruta si en la otra PC es distinta (ver sección final "Replicar en otra PC").

---

## Resumen de la arquitectura

| Lenguaje | Language Server | Runtime que lo corre | Runtime del proyecto |
|----------|----------------|---------------------|---------------------|
| Java | Eclipse JDTLS (≤1.48) | **JDK 21** | **JDK 8** (configurable) |
| TypeScript (.ts) | typescript-language-server 4.3 + Angular LS | Node 20 | TypeScript local del proyecto |
| HTML (templates) | Angular Language Server (local por proyecto) | Node 20 | Angular local del proyecto |

**Dos ideas clave que explican casi todo:**

1. **El runtime que corre el server ≠ el runtime del proyecto.** JDTLS necesita Java 21
   para arrancar, pero compila tu código con Java 8. Son dos JDK con roles distintos.
2. **En Windows, Helix no lanza bien los `.cmd`/`.ps1` como language server.** Por eso
   cada server se envuelve en un `.bat` que llama a `node`/`java` directo. Este fue el
   problema más difícil de diagnosticar.

---

## Requisitos (todo portable en `dev-tools`)

- `jdk-21\` — JDK 21 (corre JDTLS)
- `jdk8\` — JDK 8 (compila el proyecto Java)
- `jdtls\` — Eclipse JDTLS **versión ≤ 1.48** (ver trampa abajo)
- `maven\` — Maven portable con tu `conf\settings.xml` (apunta al Nexus interno)
- `nodejs-20\node\` — Node.js 20
- `nodejs-20\npm-packages\` — prefijo global de npm (en el PATH)
- Helix (`hx.exe`)

### ⚠️ Trampa #1 — La versión de JDTLS

NO uses el `jdt-language-server-latest`. Las builds recientes (1.49+) exigen **JavaSE 25**
y fallan con JDK 21 con un error en cascada:

```
Unresolved requirement: Require-Capability: osgi.ee; filter:="(&(osgi.ee=JavaSE)(version=25))"
```

Descargá una versión fechada **1.43–1.48** desde:
https://download.eclipse.org/jdtls/milestones/?d

Regla simple: **1.48.x o menos funciona con JDK 21.**

---

## 1. Java (Spring Boot / Maven)

### 1.1 Wrapper `jdtls.bat`

```bat
@echo off
chcp 65001 >nul
set "JDTLS_HOME=C:\Users\username\Documents\dev-tools\jdtls"
set "JAVA21=C:\Users\username\Documents\dev-tools\jdk-21"
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
```

**Por qué cada cosa:**
- `chcp 65001` + `-D*.encoding=UTF-8` → **Trampa #2.** Sin esto, en un Windows en español
  la JVM escribe acentos en cp1252 que contaminan el stdout del protocolo LSP, y Helix tira
  `stream did not contain valid UTF-8`. El protocolo LSP debe ser UTF-8 puro.
- `-data ...\%WS%` → cada workspace tiene su propia carpeta de datos (derivada del path).

### 1.2 Runtime del proyecto (JDK 8)

Se configura en `languages.toml` (ver sección 3). JDTLS corre con 21 pero usa el JDK 8
declarado en `runtimes` para compilar.

### 1.3 Maven y el `settings.xml`

Si tu proyecto usa un **parent POM corporativo** (ej. un Nexus interno), JDTLS debe usar tu
`settings.xml`. Si no, Maven va a Maven Central, no lo encuentra y falla con:

```
Non-resolvable parent POM ... was not found in https://repo.maven.apache.org/maven2
```

Se arregla apuntando `globalSettings`/`userSettings` al `settings.xml` correcto en
`languages.toml`. Si ya quedó un fallo cacheado, borrá los marcadores:

```powershell
Get-ChildItem "$env:USERPROFILE\.m2\repository" -Recurse -Filter "*.lastUpdated" | Remove-Item -Force
```

---

## 2. Angular (12 y 13)

### 2.1 Estrategia: un LS local por proyecto

El Angular Language Server **debe coincidir con la versión de Angular del proyecto**. Como
tenés proyectos en 12 y 13, se instala el LS **dentro del `node_modules` de cada proyecto**
(sin `--save`, para no ensuciar el `package.json`):

```powershell
# En cada proyecto (ajustar version @12 / @13 y typescript según el proyecto)
npm install --no-save "@angular/language-server@^12" "typescript@~4.3.5"
```

Un wrapper detecta cuál usar según el directorio actual.

### 2.2 TypeScript Language Server (global)

Da la navegación de los `.ts`. Versión **4.3.3** (la 6.x pide Node 22; con Node 20 usá la 4):

```powershell
npm install -g "typescript-language-server@4.3.3" "typescript@4.9.5"
```

### 2.3 Wrapper `tsls.bat`

```bat
@echo off
"C:\Users\username\Documents\dev-tools\nodejs-20\node\node.exe" "C:\Users\username\Documents\dev-tools\nodejs-20\npm-packages\node_modules\typescript-language-server\lib\cli.mjs" --stdio
```

**Por qué un `.bat` y no el comando directo:** Helix en Windows no conecta bien el stdio
cuando el server es un `.cmd`. Llamar a `node cli.mjs` directo resuelve el "no definition found".

### 2.4 Wrapper `ngserver.bat`

```bat
@echo off
setlocal enabledelayedexpansion
set "NODE=C:\Users\username\Documents\dev-tools\nodejs-20\node\node.exe"

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
```

**Qué hace:** sube directorios desde donde abriste el archivo hasta encontrar el
`@angular/language-server` del proyecto, y lo lanza con las rutas de TypeScript y Angular
(`--tsProbeLocations`/`--ngProbeLocations`). Así cada proyecto usa su versión sola.

### 2.5 ⚠️ Trampa #3 — ngcc

Angular 12/13 usa **ngcc** (Angular Compatibility Compiler). Hasta que ngcc no compila las
librerías de `node_modules`, el Angular LS arranca con `languageServiceEnabled: false` y no
responde en los templates. Corré ngcc **una vez por proyecto** antes de usarlo:

```powershell
# dentro del proyecto Angular
node ".\node_modules\@angular\compiler-cli\ngcc\main-ngcc.js"
```

Nota: el Angular LS viejo manda notificaciones `$/progress` que Helix no entiende y loguea
como `ProgressParamsValue`. Es **ruido inofensivo** mientras el autocompletado funcione.

---

## 3. `languages.toml` completo

Ubicación en Windows: `%APPDATA%\helix\languages.toml`
(= `C:\Users\<usuario>\AppData\Roaming\helix\languages.toml`)

```toml
[language-server.jdtls]
command = "C:\\Users\\username\\Documents\\dev-tools\\jdtls.bat"

[language-server.jdtls.config]
java.import.maven.enabled = true
java.configuration.updateBuildConfiguration = "automatic"
java.progressReports.enabled = true
java.maven.downloadSources = true
java.configuration.maven.globalSettings = "D:\\Users\\username\\Documents\\dev-tools\\maven\\conf\\settings.xml"
java.configuration.maven.userSettings = "C:\\Users\\username\\Documents\\dev-tools\\maven\\conf\\settings.xml"

[[language-server.jdtls.config.java.configuration.runtimes]]
name = "JavaSE-1.8"
path = "C:\\Users\\username\\Documents\\dev-tools\\jdk8"
default = true

[[language]]
name = "java"
language-servers = ["jdtls"]
roots = ["pom.xml", "build.gradle", ".git", "mvnw"]

[language-server.typescript-language-server]
command = "C:\\Users\\username\\Documents\\dev-tools\\tsls.bat"

[language-server.angular]
command = "C:\\Users\\username\\Documents\\dev-tools\\ngserver.bat"

[[language]]
name = "typescript"
roots = ["angular.json", "package.json", "tsconfig.json", ".git"]
language-servers = ["typescript-language-server", "angular"]

[[language]]
name = "html"
roots = ["angular.json", "package.json", "tsconfig.json", ".git"]
language-servers = ["angular"]
```

**Por qué `typescript` tiene DOS servers:** el `typescript-language-server` resuelve símbolos
TS normales (gd, hover). El `angular` agrega lo suyo: `gd` sobre `templateUrl`/`styleUrls` y
referencias de templates. Juntos cubren todo. Si sacás `angular` de acá, `gd` sobre
`templateUrl` deja de saltar al `.html`.

---

## 4. Verificar que todo quedó bien

```powershell
hx --health java        # jdtls en verde
hx --health typescript  # typescript-language-server + angular en verde
hx --health html        # angular en verde
```

Al abrir un proyecto:
- `:log-open` muestra la actividad de los servers.
- Java: la primera vez el import Maven tarda minutos; se completa cuando aparece el `.classpath`.
- Angular: dale unos segundos al primer `.html` (análisis inicial).

---

## 5. Replicar en otra PC

1. Copiá toda la carpeta `dev-tools` (incluye JDKs, Maven, Node, JDTLS, Helix, los `.bat`).
2. Si la ruta cambia (otro usuario/disco), **buscá y reemplazá** la ruta vieja por la nueva
   en: los 3 `.bat` y el `languages.toml`.
3. Copiá `languages.toml` a `%APPDATA%\helix\`.
4. Instalá el TS LS global: `npm install -g typescript-language-server@4.3.3 typescript@4.9.5`
5. En cada proyecto Angular: instalá su LS local (`--no-save`) y corré ngcc una vez.
6. Verificá con `hx --health`.

O usá el script automatizado: `setup-helix.ps1` (ver siguiente archivo).

---

## 6. Formateo de código

Formateo **manual** con `:format` (no automático al guardar).

| Lenguaje | Formateador | Config |
|----------|-------------|--------|
| Java | jdtls + perfil `MiEstilo` de `eclipse-formatter.xml` | en `jdtls.config` |
| TypeScript | Prettier (parser typescript) | `formatter` en `[[language]]` |
| HTML/templates | Prettier (parser angular) | `formatter` en `[[language]]` |

### 6.1 Instalar Prettier (global)

```powershell
npm install -g "prettier@2.8.8"
```
(La 2.8.x es estable con Node 20 y Angular 12/13.)

### 6.2 Wrapper `prettier.bat`

Mismo motivo que los demás wrappers: en Windows conviene `node` directo.

```bat
@echo off
"C:\Users\username\Documents\dev-tools\nodejs-20\node\node.exe" "C:\Users\username\Documents\dev-tools\nodejs-20\npm-packages\node_modules\prettier\bin-prettier.js" %*
```

### 6.3 Java — añadir al bloque `jdtls.config`

```toml
java.format.settings.url = "C:\\Users\\username\\Documents\\dev-tools\\ecplise-xml\\eclipse-formatter.xml"
java.format.settings.profile = "MiEstilo"
```

### 6.4 TS/HTML — añadir el `formatter` a cada `[[language]]`

```toml
# dentro de [[language]] name = "typescript"
formatter = { command = "C:\\Users\\username\\Documents\\dev-tools\\prettier.bat", args = ["--parser", "typescript"] }

# dentro de [[language]] name = "html"
formatter = { command = "C:\\Users\\username\\Documents\\dev-tools\\prettier.bat", args = ["--parser", "angular"] }
```

Nota: en Java, `hx --health java` muestra `Configured formatter: None` — es **normal**:
Java formatea vía LSP (jdtls), no con un formateador externo. `:format` igual funciona.

---

## 7. Flujo de trabajo diario (crear archivos, componentes)

**Idea clave: Helix es un EDITOR, no un IDE con árbol de archivos.** No hay panel lateral ni
"click derecho → nuevo archivo". Crear archivos y andar en el filesystem es trabajo de la
**terminal**. En Windows se trabaja con el editor y la terminal lado a lado.

### 7.1 Pantalla dividida en Cmder

| Atajo | Acción |
|-------|--------|
| `Ctrl+Shift+E` | dividir panel **vertical** (izq/der) ← ideal para editor+terminal |
| `Ctrl+Shift+O` | dividir panel **horizontal** (arriba/abajo) |
| `Ctrl+Tab` | saltar entre paneles |
| `Ctrl+W` | cerrar panel activo |

Flujo recomendado:
```
Cmder
├── Ctrl+Shift+E
├── Panel IZQUIERDO: Helix (editor)
└── Panel DERECHO:   terminal libre (ng, mvn, git, crear archivos)
```

### 7.2 Crear archivos DESDE Helix

- **Abrir/crear por ruta:** `:o src\app\cosas\nuevo.component.ts`
  Si la ruta no existe, abre un buffer; al hacer `:w` crea el archivo **y las carpetas que falten**.
- **Guardar a ruta nueva:** `:w ruta\archivo.ext`
- **Buscar archivos:** `Espacio` + `f` (file picker)
- **Correr un comando shell sin salir:** `:sh <comando>`  (ej. `:sh ng g c foo`)

### 7.3 Componentes Angular (panel derecho)

```cmd
ng g c mi-componente        # crea .ts .html .scss .spec.ts y actualiza el modulo
ng g s servicios/mi-servicio   # servicio
```
Luego en Helix: `:o src\app\mi-componente\mi-componente.component.ts`

### 7.4 Clases Java

**Spring Boot/Maven NO tiene un "generate" como Angular.** Las clases se crean a mano:

- **Desde Helix (lo más rápido):** `:o src\main\java\gt\gob\sat\paquete\MiClase.java` → escribir → `:w`
- **Desde la terminal:** `type nul > src\main\java\gt\gob\sat\paquete\MiClase.java`
- jdtls autocompleta el esqueleto de la clase al empezar a escribir en un `.java` vacío.

### 7.5 Detalle importante

Cuando creás un archivo **nuevo desde la terminal** (fuera de Helix), el language server
(jdtls o Angular) puede tardar unos segundos en indexarlo. Si no aparece el autocompletado
enseguida, dale un momento o reabrí el archivo.

---

## 8. Mantenimiento / Troubleshooting

### 8.1 jdtls se cuelga o da timeout

**Síntoma:** jdtls tarda eternidades en arrancar, o en `helix.log` aparece:
```
failed to initialize language server: request 0 timed out
Tried sending response into a closed channel ... original request likely timed out
```

**Causa:** Helix en Windows a veces **no mata el proceso jdtls al salir**. Se van acumulando
procesos `java.exe` huérfanos que siguen agarrados al lock del workspace (`.jdtls-data`).
Cuando abrís Helix de nuevo, el jdtls nuevo no puede tomar el lock → se traba → Helix corta
por timeout. **No es la config: son procesos zombi.**

**Fix:** cerrá Helix y corré el script de limpieza:
```cmd
C:\Users\username\Documents\dev-tools\limpiar-jdtls.bat
```
Luego reabrí Helix. El workspace indexado se conserva, así que jdtls arranca rápido.

### 8.2 `limpiar-jdtls.bat`

Mata **solo** los procesos jdtls (filtra por `jdt.ls.core`), así NO toca otras apps Java
(Spring Boot levantado, DBeaver, etc.). También libera el `.lock` del workspace.

```bat
@echo off
REM Mata solo los procesos jdtls (Eclipse JDT Language Server) huerfanos.
REM Filtra por "jdt.ls.core" para NO tocar otras apps Java (Spring Boot, DBeaver, etc.).

echo Buscando procesos jdtls...

set "FOUND="
for /f "usebackq tokens=1" %%P in (`powershell -NoProfile -Command "Get-Process java -ErrorAction SilentlyContinue | Where-Object { (Get-CimInstance Win32_Process -Filter ('ProcessId=' + $_.Id)).CommandLine -like '*jdt.ls.core*' } | Select-Object -ExpandProperty Id"`) do (
  echo   Matando jdtls PID %%P
  taskkill /PID %%P /F >nul 2>&1
  set "FOUND=1"
)

if not defined FOUND (
  echo No hay procesos jdtls corriendo. Nada que limpiar.
) else (
  echo Esperando cierre completo...
  timeout /t 2 /nobreak >nul
  echo Listo. Procesos jdtls terminados.
)

REM Libera el lock del workspace si quedo colgado
if exist "%USERPROFILE%\.jdtls-data" (
  for /r "%USERPROFILE%\.jdtls-data" %%L in (.lock) do (
    del /f /q "%%L" >nul 2>&1
  )
)

echo.
echo Ya podes reabrir Helix.
```

Este `.bat` no tiene rutas hardcodeadas (usa `%USERPROFILE%` y busca por nombre de proceso),
así que funciona igual en otra PC sin editarlo.

### 8.3 Comandos útiles de diagnóstico

```powershell
# Ver cuantos jdtls hay corriendo
Get-Process java -ErrorAction SilentlyContinue

# Ver la linea de comando de cada java (para distinguir jdtls de otras apps)
Get-CimInstance Win32_Process -Filter "name = 'java.exe'" | Select-Object ProcessId, CommandLine
```

Dentro de Helix:
- `:log-open` — ver la actividad y errores de los language servers en vivo.
- `hx --health <lenguaje>` — confirmar que los servers y formatters estan configurados.

---

## Apéndice — Problemas que resolvimos (historial de diagnóstico)

| Síntoma | Causa raíz | Fix |
|---------|-----------|-----|
| `osgi.ee ... version=25` en cascada | JDTLS `latest` pide Java 25 | Bajar a JDTLS ≤1.48 |
| `stream did not contain valid UTF-8` | stdout con acentos cp1252 | `chcp 65001` + `-D*.encoding=UTF-8` |
| Import Maven termina en 83ms, sin `.classpath` | proyecto Eclipse zombi + parent POM no resuelto | borrar `.project/.settings/.jdtls-data` + apuntar `settings.xml` |
| `Non-resolvable parent POM` | JDTLS no usaba el settings.xml del Nexus | `maven.globalSettings`/`userSettings` + borrar `.lastUpdated` |
| `.ts` "no definition found" | el LSP no tenía TypeScript (backend muerto) | instalar `typescript` junto al LS + wrapper `.bat` |
| `.ts` sigue sin andar aun con TS ok | Helix no conecta `.cmd` en Windows | envolver en `tsls.bat` con `node` directo |
| Angular LS `StreamClosed` / templates sin soporte | ngcc no compilado | correr `ngcc` una vez por proyecto |
| `gd` sobre `templateUrl` dejó de saltar | `except-features` bloqueaba al Angular LS en `.ts` | atar `angular` también a `typescript` |
| jdtls timeout / `closed channel` | procesos jdtls huérfanos agarrados al lock | `limpiar-jdtls.bat` (matar zombis + liberar lock) |
