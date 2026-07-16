param([string]$ProjectPath = ".")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\02_reporte_caja_blanca.html"
Initialize-QualityReport -Titulo "02. Reporte de caja blanca - revision interna PHP" -Descripcion "Analiza la sintaxis de archivos PHP y senales internas de mantenibilidad sin usar la interfaz del usuario." -Categoria "Caja blanca" -ProjectPath $root

$phpFiles = Get-ChildItem -Path $root -Recurse -Filter *.php -File | Where-Object { $_.FullName -notmatch "\\vendor\\|\\node_modules\\" }
Add-QualityCheck "Archivos PHP detectados" "APROBADO" "Media" "Se encontraron archivos PHP para revision interna." "Cantidad: $(@($phpFiles).Count)" "Mantener la revision de sintaxis en cada entrega."

$phpCmd = Get-Command php -ErrorAction SilentlyContinue
if ($null -eq $phpCmd) {
    Add-QualityCheck "PHP disponible para lint" "NO EJECUTADO" "Alta" "No se encontro PHP en PATH." "php" "Instalar PHP o agregarlo al PATH para ejecutar php -l."
} else {
    $errores = @()
    foreach ($file in $phpFiles) {
        $result = & php -l $file.FullName 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { $errores += "$($file.FullName): $result" }
    }
    if (@($errores).Count -eq 0) {
        Add-QualityCheck "Sintaxis PHP" "APROBADO" "Alta" "Todos los archivos PHP pasaron php -l." "Archivos revisados: $(@($phpFiles).Count)" "Continuar ejecutando esta prueba antes de presentar el sistema."
    } else {
        Add-QualityCheck "Sintaxis PHP" "FALLO" "Alta" "Se encontraron errores de sintaxis." ($errores -join "`n---`n") "Corregir los archivos senalados y volver a ejecutar la prueba."
    }
}

$large = @()
foreach ($file in $phpFiles) {
    $lines = @(Get-Content $file.FullName -ErrorAction SilentlyContinue).Count
    if ($lines -gt 350) { $large += "$($file.FullName) -> $lines lineas" }
}
if (@($large).Count -eq 0) {
    Add-QualityCheck "Tamanio de archivos" "APROBADO" "Media" "No se detectaron archivos PHP excesivamente extensos." "Umbral usado: 350 lineas" "Mantener controlado el tamanio de controladores y modelos."
} else {
    Add-QualityCheck "Tamanio de archivos" "ADVERTENCIA" "Media" "Hay archivos grandes que pueden ser dificiles de mantener." ($large -join "`n") "Dividir responsabilidades o extraer funciones si el archivo crece mas."
}

$controllers = Get-ChildItem -Path (Join-Path $root "controllers") -Filter *.php -File -ErrorAction SilentlyContinue
$models = Get-ChildItem -Path (Join-Path $root "models") -Filter *.php -File -ErrorAction SilentlyContinue
if (@($controllers).Count -gt 0 -and @($models).Count -gt 0) {
    Add-QualityCheck "Separacion MVC" "APROBADO" "Alta" "El proyecto mantiene carpetas de controladores y modelos." "Controllers: $(@($controllers).Count)`nModels: $(@($models).Count)" "Mantener la logica de negocio separada de las vistas."
} else {
    Add-QualityCheck "Separacion MVC" "FALLO" "Alta" "No se encontraron controladores o modelos suficientes." "Controllers: $(@($controllers).Count)`nModels: $(@($models).Count)" "Revisar estructura MVC del proyecto."
}

$todoMatches = Select-String -Path $phpFiles.FullName -Pattern "TODO|FIXME|var_dump\(|print_r\(" -SimpleMatch:$false -ErrorAction SilentlyContinue
if ($null -eq $todoMatches -or @($todoMatches).Count -eq 0) {
    Add-QualityCheck "Codigo de depuracion pendiente" "APROBADO" "Media" "No se detectaron marcas TODO, FIXME, var_dump o print_r." "Sin hallazgos" "Evitar dejar codigo de depuracion en la version final."
} else {
    $evidence = ($todoMatches | Select-Object -First 30 | ForEach-Object { "$($_.Path):$($_.LineNumber) -> $($_.Line.Trim())" }) -join "`n"
    Add-QualityCheck "Codigo de depuracion pendiente" "ADVERTENCIA" "Media" "Se detectaron marcas o salidas de depuracion." $evidence "Retirar o justificar estas lineas antes de entregar."
}

$functionMatches = Select-String -Path $phpFiles.FullName -Pattern "function\s+[A-Za-z0-9_]+\s*\(" -ErrorAction SilentlyContinue
$classMatches = Select-String -Path $phpFiles.FullName -Pattern "class\s+[A-Za-z0-9_]+" -ErrorAction SilentlyContinue
Add-QualityCheck "Inventario interno de clases y funciones" "APROBADO" "Baja" "Se genero un conteo tecnico del codigo PHP." "Clases: $(@($classMatches).Count)`nFunciones/metodos: $(@($functionMatches).Count)" "Usar este inventario para sustentar la revision estructural."

Write-QualityHtmlReport -OutFile $out
