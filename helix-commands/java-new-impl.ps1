param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("class", "interface", "enum")]
    [string]$Tipo,

    [Parameter(Mandatory = $true)]
    [string]$RutaClase
)

$ErrorActionPreference = "Stop"

$srcRoot = Join-Path (Get-Location) "src\main\java"
if (-not (Test-Path $srcRoot)) {
    Write-Error "No se encontro 'src\main\java' bajo el directorio actual: $(Get-Location). Abri Helix en la raiz del microservicio."
    exit 1
}

$rutaNormalizada = ($RutaClase -replace "/", "\").TrimEnd("\") -replace "\.java$", ""
$rutaNormalizada = $rutaNormalizada -replace "^src\\main\\java\\", ""
$rutaCompleta = Join-Path $srcRoot "$rutaNormalizada.java"

if (Test-Path $rutaCompleta) {
    Write-Error "El archivo ya existe: $rutaCompleta"
    exit 1
}

$nombreClase = [System.IO.Path]::GetFileNameWithoutExtension($rutaCompleta)
$dirDestino = Split-Path $rutaCompleta -Parent
$cultura = [System.Globalization.CultureInfo]::GetCultureInfo('es-ES')
$fechaCreacion = (Get-Date).ToString("dddd dd 'de' MMMM 'de' yyyy HH:mm:ss", $cultura)

$rutaPackage = $dirDestino.Substring($srcRoot.Length).TrimStart("\")
$package = $rutaPackage -replace "\\", "."

New-Item -ItemType Directory -Path $dirDestino -Force | Out-Null

$lineas = @()
if ($package) {
    $lineas += "package $package;"
    $lineas += ""
}

$lineas += "/*"
$lineas += " * Creado por @rfsartio"
$lineas += " * Clase: $nombreClase"
$lineas += " * Fecha: $fechaCreacion"
$lineas += " */"
$lineas += "public $Tipo $nombreClase {"
$lineas += ""
$lineas += "}"

$contenido = ($lineas -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($rutaCompleta, $contenido, (New-Object System.Text.UTF8Encoding $false))

[System.IO.File]::WriteAllText("C:\Users\username\Documents\helix-commands\.last-new", $rutaCompleta, (New-Object System.Text.UTF8Encoding $false))

Write-Output $rutaCompleta
