@echo off
chcp 65001 >nul
set "JDTLS_HOME=C:\Users\username\Documents\java-configs\jdtls"
set "JAVA21=C:\Users\username\Documents\java-configs\jdk-21"
for %%f in ("%JDTLS_HOME%\plugins\org.eclipse.equinox.launcher_*.jar") do set "LAUNCHER=%%f"
set "WS=%CC::=%"
set "WS=%WS:\=_%"
"%JAVA21%\bin\java.exe" ^
  -Dfile.encoding=UTF-8 ^
  -Dstdout.encoding=UTF-8 ^
  -Dstderr.encoding=UTF-8 ^
  -javaagent:"C:\Users\username\Documents\java-configs\librerias\org\projectlombok\lombok\1.18.30\lombok-1.18.30.jar" ^
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
