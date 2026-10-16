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
