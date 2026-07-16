param([string]$ProjectPath = ".")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\04_reporte_integracion.html"
Initialize-QualityReport -Titulo "04. Reporte de integracion MVC" -Descripcion "Comprueba que rutas, controladores, metodos, vistas y archivos base esten conectados de forma coherente." -Categoria "Integracion" -ProjectPath $root

$index = Join-Path $root "public\index.php"
if (-not (Test-Path $index)) {
    Add-QualityCheck "Archivo de rutas public/index.php" "FALLO" "Alta" "No existe public/index.php." $index "Restaurar el archivo principal de rutas."
    Write-QualityHtmlReport -OutFile $out
    exit
}

$content = Get-Content $index -Raw
$routePattern = "\`$router->(get|post)\('([^']+)',\s*\[([A-Za-z0-9_\\]+)::class,\s*'([^']+)'\]\)"
$matches = [regex]::Matches($content, $routePattern)
if ($matches.Count -gt 0) {
    Add-QualityCheck "Rutas declaradas" "APROBADO" "Alta" "Se encontraron rutas GET/POST declaradas en public/index.php." "Cantidad de rutas: $($matches.Count)" "Mantener las rutas centralizadas y documentadas."
} else {
    Add-QualityCheck "Rutas declaradas" "FALLO" "Alta" "No se detectaron rutas con el patron esperado." "Patron: router->get/post" "Revisar public/index.php."
}

$missingControllers = @()
$missingMethods = @()
foreach ($m in $matches) {
    $methodHttp = $m.Groups[1].Value
    $route = $m.Groups[2].Value
    $classFull = $m.Groups[3].Value
    $method = $m.Groups[4].Value
    $className = ($classFull -split "\\")[-1]
    $controllerFile = Join-Path $root ("controllers\" + $className + ".php")
    if (-not (Test-Path $controllerFile)) {
        $missingControllers += "$methodHttp $route -> $className.php"
    } else {
        $controllerSource = Get-Content $controllerFile -Raw
        if ($controllerSource -notmatch ("function\s+" + [regex]::Escape($method) + "\s*\(")) {
            $missingMethods += "$methodHttp $route -> $className::$method"
        }
    }
}
if (@($missingControllers).Count -eq 0) {
    Add-QualityCheck "Controladores enlazados a rutas" "APROBADO" "Alta" "Todas las rutas apuntan a controladores existentes." "Rutas revisadas: $($matches.Count)" "Mantener nombres de clases y archivos consistentes."
} else {
    Add-QualityCheck "Controladores enlazados a rutas" "FALLO" "Alta" "Hay rutas que apuntan a controladores inexistentes." ($missingControllers -join "`n") "Crear o corregir los controladores indicados."
}
if (@($missingMethods).Count -eq 0) {
    Add-QualityCheck "Metodos de controlador" "APROBADO" "Alta" "Los metodos usados por las rutas existen en sus controladores." "Rutas revisadas: $($matches.Count)" "Evitar renombrar metodos sin actualizar la ruta."
} else {
    Add-QualityCheck "Metodos de controlador" "FALLO" "Alta" "Hay rutas que llaman metodos no encontrados." ($missingMethods -join "`n") "Implementar los metodos o corregir la ruta."
}

$controllerFiles = Get-ChildItem -Path (Join-Path $root "controllers") -Filter *.php -File -ErrorAction SilentlyContinue
$renderMatches = @()
foreach ($cf in $controllerFiles) {
    $src = Get-Content $cf.FullName -Raw
    $r = [regex]::Matches($src, "render\('([^']+)'")
    foreach ($one in $r) { $renderMatches += [PSCustomObject]@{File=$cf.FullName; View=$one.Groups[1].Value} }
}
$missingViews = @()
foreach ($rm in $renderMatches) {
    $viewPath = Join-Path $root ("views\" + $rm.View + ".php")
    if (-not (Test-Path $viewPath)) { $missingViews += "$($rm.View) usado en $($rm.File)" }
}
if (@($renderMatches).Count -eq 0) {
    Add-QualityCheck "Vistas usadas por controladores" "ADVERTENCIA" "Media" "No se detectaron llamadas render() con comillas simples." "Sin coincidencias" "Verificar manualmente si se usa otro patron de renderizado."
} elseif (@($missingViews).Count -eq 0) {
    Add-QualityCheck "Vistas usadas por controladores" "APROBADO" "Alta" "Todas las vistas referenciadas por render() existen." "Vistas revisadas: $(@($renderMatches).Count)" "Mantener sincronizados controladores y vistas."
} else {
    Add-QualityCheck "Vistas usadas por controladores" "FALLO" "Alta" "Hay vistas referenciadas que no existen." ($missingViews -join "`n") "Crear la vista o corregir la ruta de renderizado."
}

$required = @("includes\app.php", "includes\database.php", "models\ActiveRecord.php", "Router.php", "vendor\autoload.php")
foreach ($f in $required) {
    $p = Join-Path $root $f
    if (Test-Path $p) {
        Add-QualityCheck "Dependencia de integracion: $f" "APROBADO" "Media" "Archivo disponible." $p "Conservar para que la integracion cargue correctamente."
    } else {
        $state = if ($f -eq "vendor\autoload.php") { "ADVERTENCIA" } else { "FALLO" }
        Add-QualityCheck "Dependencia de integracion: $f" $state "Alta" "Archivo no encontrado." $p "Ejecutar composer install o restaurar el archivo faltante."
    }
}

Write-QualityHtmlReport -OutFile $out
