param([string]$ProjectPath = ".")
$ErrorActionPreference = "Continue"
$lib = Join-Path $PSScriptRoot "lib\reporte.ps1"
. $lib
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\01_reporte_entorno.html"
Initialize-QualityReport -Titulo "01. Reporte de entorno y precondiciones" -Descripcion "Verifica que el proyecto tenga la estructura, dependencias y herramientas minimas antes de ejecutar pruebas tecnicas." -Categoria "Entorno" -ProjectPath $root

function Test-CommandExists([string]$CommandName) {
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return $false }
    return $true
}

Add-QualityCheck "Ruta del proyecto" "APROBADO" "Alta" "Se resolvio la carpeta raiz del proyecto." $root "Ejecutar siempre las pruebas desde la raiz del sistema."

$folders = @("controllers", "models", "views", "public", "includes", "classes", "src")
foreach ($f in $folders) {
    $p = Join-Path $root $f
    if (Test-Path $p) {
        Add-QualityCheck "Carpeta requerida: $f" "APROBADO" "Alta" "La carpeta existe." $p "Mantener esta estructura para que el framework MVC funcione."
    } else {
        Add-QualityCheck "Carpeta requerida: $f" "FALLO" "Alta" "La carpeta no existe." $p "Restaurar la carpeta o revisar si el proyecto esta incompleto."
    }
}

$files = @("composer.json", "package.json", "Router.php", "public\index.php", "includes\app.php", "includes\database.php", "includes\.env")
foreach ($f in $files) {
    $p = Join-Path $root $f
    if (Test-Path $p) {
        Add-QualityCheck "Archivo requerido: $f" "APROBADO" "Alta" "El archivo existe." $p "Conservar este archivo dentro del proyecto."
    } else {
        Add-QualityCheck "Archivo requerido: $f" "FALLO" "Alta" "El archivo no fue encontrado." $p "Agregar el archivo faltante antes de ejecutar el sistema."
    }
}

$tools = @(
    @{Name="PHP"; Cmd="php"; Version="php -v"; Rec="Instalar PHP y agregarlo al PATH de Windows."},
    @{Name="Composer"; Cmd="composer"; Version="composer --version"; Rec="Ejecutar composer install cuando el proyecto tenga composer.json."},
    @{Name="Node.js"; Cmd="node"; Version="node -v"; Rec="Instalar Node.js LTS para compilar recursos frontend."},
    @{Name="npm"; Cmd="npm"; Version="npm -v"; Rec="Ejecutar npm install y npm run dev cuando corresponda."},
    @{Name="k6"; Cmd="k6"; Version="k6 version"; Rec="Instalar k6 para pruebas de rendimiento, carga y estres."}
)
foreach ($t in $tools) {
    if (Test-CommandExists $t.Cmd) {
        $version = try { Invoke-Expression $t.Version 2>&1 | Out-String } catch { $_.Exception.Message }
        Add-QualityCheck "Herramienta instalada: $($t.Name)" "APROBADO" "Media" "La herramienta esta disponible en PATH." $version.Trim() $t.Rec
    } else {
        Add-QualityCheck "Herramienta instalada: $($t.Name)" "ADVERTENCIA" "Media" "La herramienta no esta disponible en PATH." $t.Cmd $t.Rec
    }
}

$vendor = Join-Path $root "vendor"
if (Test-Path $vendor) {
    Add-QualityCheck "Dependencias PHP vendor" "APROBADO" "Alta" "La carpeta vendor existe." $vendor "Si el sistema falla por autoload, volver a ejecutar composer install."
} else {
    Add-QualityCheck "Dependencias PHP vendor" "ADVERTENCIA" "Alta" "La carpeta vendor no existe." $vendor "Ejecutar composer install antes de levantar el sistema."
}

$nodeModules = Join-Path $root "node_modules"
if (Test-Path $nodeModules) {
    Add-QualityCheck "Dependencias Node node_modules" "APROBADO" "Media" "La carpeta node_modules existe." $nodeModules "Si faltan recursos frontend, ejecutar npm install."
} else {
    Add-QualityCheck "Dependencias Node node_modules" "ADVERTENCIA" "Media" "La carpeta node_modules no existe." $nodeModules "Ejecutar npm install si se requiere compilar SCSS o JS."
}

$sql1 = Join-Path $root "BD.sql"
$sql2 = Join-Path (Split-Path $root -Parent) "BD.sql"
if ((Test-Path $sql1) -or (Test-Path $sql2)) {
    Add-QualityCheck "Archivo de base de datos BD.sql" "APROBADO" "Alta" "Se encontro el script de base de datos." "$sql1`n$sql2" "Restaurar la base antes de probar rutas que consultan datos."
} else {
    Add-QualityCheck "Archivo de base de datos BD.sql" "ADVERTENCIA" "Alta" "No se encontro BD.sql cerca del proyecto." "$sql1`n$sql2" "Colocar BD.sql en la raiz o restaurar manualmente la base en SQL Server."
}

Write-QualityHtmlReport -OutFile $out
