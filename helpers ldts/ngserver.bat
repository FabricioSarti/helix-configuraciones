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
