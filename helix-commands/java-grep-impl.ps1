param(
    [Parameter(Mandatory = $true)]
    [string]$Palabra,

    [Parameter(Mandatory = $false)]
    [string]$SubDir = ""
)

$ErrorActionPreference = "Stop"

$srcRoot = Join-Path (Get-Location) "src\main\java"
if (-not (Test-Path $srcRoot)) {
    Write-Error "No se encontro 'src\main\java' bajo el directorio actual: $(Get-Location). Abri Helix en la raiz del microservicio."
    exit 1
}

$dirBusqueda = $srcRoot
if ($SubDir) {
    $subNormalizado = ($SubDir -replace "/", "\").TrimEnd("\") -replace "^src\\main\\java\\", ""
    $dirBusqueda = Join-Path $srcRoot $subNormalizado
    if (-not (Test-Path $dirBusqueda)) {
        Write-Error "El directorio no existe: $dirBusqueda"
        exit 1
    }
}

$archivos = Get-ChildItem -Path $dirBusqueda -Recurse -Filter "*.java" -File
if (-not $archivos) {
    Write-Output "No hay archivos .java en: $dirBusqueda"
    exit 0
}

$resultados = $archivos | Select-String -Pattern $Palabra -SimpleMatch
foreach ($r in $resultados) {
    Write-Output "$($r.Path):$($r.LineNumber): $($r.Line.Trim())"
}

if (-not $resultados) {
    Write-Output "Sin coincidencias para '$Palabra' en: $dirBusqueda"
}
