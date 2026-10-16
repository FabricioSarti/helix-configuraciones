param(
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

if (-not (Test-Path $rutaCompleta)) {
    Write-Error "El archivo no existe: $rutaCompleta"
    exit 1
}

Remove-Item -Path $rutaCompleta -Force

Write-Output "Eliminado: $rutaCompleta"
