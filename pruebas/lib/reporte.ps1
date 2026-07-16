# Libreria interna para crear reportes HTML claros.
# No ejecutar este archivo directamente. Es usado por cada prueba separada.

function Initialize-QualityReport {
    param(
        [string]$Titulo,
        [string]$Descripcion,
        [string]$Categoria,
        [string]$ProjectPath
    )
    $script:ReportTitle = $Titulo
    $script:ReportDescription = $Descripcion
    $script:ReportCategory = $Categoria
    $script:ProjectRoot = (Resolve-Path $ProjectPath).Path
    $script:Checks = @()
    $script:StartedAt = Get-Date
}

function Add-QualityCheck {
    param(
        [string]$Nombre,
        [string]$Estado,
        [string]$Severidad,
        [string]$Detalle,
        [string]$Evidencia,
        [string]$Recomendacion
    )
    $script:Checks = $script:Checks + [PSCustomObject]@{
        Nombre = $Nombre
        Estado = $Estado
        Severidad = $Severidad
        Detalle = $Detalle
        Evidencia = $Evidencia
        Recomendacion = $Recomendacion
    }
}

function Escape-Html {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-StatusClass {
    param([string]$Estado)
    switch ($Estado) {
        "APROBADO" { return "ok" }
        "FALLO" { return "fail" }
        "ADVERTENCIA" { return "warn" }
        "NO EJECUTADO" { return "skip" }
        default { return "skip" }
    }
}

function Get-ConclusionText {
    param([int]$Passed, [int]$Failed, [int]$Warnings, [int]$Skipped)
    if ($Failed -gt 0) {
        return "La prueba encontro fallos que deben corregirse antes de considerar estable esta categoria. Revise las filas marcadas en rojo y atienda primero las de severidad alta."
    }
    if ($Warnings -gt 0) {
        return "La prueba no encontro fallos criticos, pero si advertencias que conviene corregir para mejorar la calidad del sistema."
    }
    if ($Skipped -gt 0) {
        return "La prueba se genero correctamente, aunque algunas verificaciones no pudieron ejecutarse por falta de herramientas, servidor o dependencias."
    }
    return "La prueba fue aprobada en los criterios evaluados. Conserve este reporte como evidencia tecnica."
}

function Write-QualityHtmlReport {
    param([string]$OutFile)

    $ended = Get-Date
    $duration = New-TimeSpan -Start $script:StartedAt -End $ended
    $total = @($script:Checks).Count
    $passed = @($script:Checks | Where-Object { $_.Estado -eq "APROBADO" }).Count
    $failed = @($script:Checks | Where-Object { $_.Estado -eq "FALLO" }).Count
    $warnings = @($script:Checks | Where-Object { $_.Estado -eq "ADVERTENCIA" }).Count
    $skipped = @($script:Checks | Where-Object { $_.Estado -eq "NO EJECUTADO" }).Count
    $conclusion = Get-ConclusionText -Passed $passed -Failed $failed -Warnings $warnings -Skipped $skipped

    $rows = New-Object System.Text.StringBuilder
    foreach ($c in $script:Checks) {
        $class = Get-StatusClass $c.Estado
        [void]$rows.AppendLine("<tr>")
        [void]$rows.AppendLine("<td><strong>$(Escape-Html $c.Nombre)</strong><span class='small'>Severidad: $(Escape-Html $c.Severidad)</span></td>")
        [void]$rows.AppendLine("<td><span class='estado $class'>$(Escape-Html $c.Estado)</span></td>")
        [void]$rows.AppendLine("<td>$(Escape-Html $c.Detalle)</td>")
        [void]$rows.AppendLine("<td><pre>$(Escape-Html $c.Evidencia)</pre></td>")
        [void]$rows.AppendLine("<td>$(Escape-Html $c.Recomendacion)</td>")
        [void]$rows.AppendLine("</tr>")
    }

    # Numero de reporte simple tipo folio, para que parezca documentacion de control interno
    $folio = "PS-" + (Get-Date $script:StartedAt -Format "yyyyMMdd-HHmm")

    $html = @"
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Escape-Html $script:ReportTitle)</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#e9e9e9;font-family:Calibri,"Segoe UI",Arial,sans-serif;color:#222;line-height:1.5}
.page{max-width:960px;margin:26px auto 60px;background:#ffffff;padding:46px 56px;border:1px solid #c9c9c9;box-shadow:0 1px 4px rgba(0,0,0,.15)}
.folio{text-align:right;font-size:11px;color:#666;margin-bottom:2px}
.encabezado{border-bottom:3px double #333;padding-bottom:12px;margin-bottom:18px}
.encabezado h1{margin:0 0 4px;font-size:20px;font-weight:700;color:#111}
.encabezado .desc{font-size:13px;color:#444;margin:0}
.datos-generales{width:100%;border-collapse:collapse;margin:14px 0 22px;font-size:13px}
.datos-generales td{padding:5px 8px;border:1px solid #ccc;vertical-align:top}
.datos-generales td.et{background:#f2f2f2;font-weight:700;width:190px}
h2.tit{font-size:15px;margin:26px 0 8px;padding-bottom:4px;border-bottom:1px solid #999;color:#111}
.resumen-tabla{width:100%;border-collapse:collapse;margin-bottom:6px;font-size:13px}
.resumen-tabla th{background:#333;color:#fff;padding:7px 8px;text-align:left;font-weight:600}
.resumen-tabla td{padding:7px 8px;border:1px solid #ccc}
.conclusion{margin-top:10px;padding:10px 12px;border:1px solid #ccc;border-left:4px solid #555;background:#fafafa;font-size:13px}
table.detalle{width:100%;border-collapse:collapse;margin-top:8px;font-size:12.5px}
table.detalle th{background:#e6e6e6;color:#222;padding:7px 8px;text-align:left;border:1px solid #bbb;font-weight:700}
table.detalle td{padding:7px 8px;border:1px solid #ccc;vertical-align:top}
table.detalle tr:nth-child(even){background:#fafafa}
.small{display:block;color:#666;font-size:11px;margin-top:3px}
.estado{font-weight:700}
.estado.ok{color:#1a6b3c}
.estado.fail{color:#a3251d}
.estado.warn{color:#946200}
.estado.skip{color:#555}
pre{white-space:pre-wrap;word-break:break-word;margin:0;background:#f5f5f0;border:1px solid #ddd;padding:6px 8px;max-height:210px;overflow:auto;font-family:Consolas,"Courier New",monospace;font-size:11.5px;color:#333}
.pie{margin-top:34px;padding-top:12px;border-top:1px solid #ccc;font-size:11px;color:#777}
@media print{body{background:#fff}.page{box-shadow:none;border:none;margin:0;padding:20px}}
@media(max-width:800px){.page{padding:22px 18px}table.detalle{display:block;overflow-x:auto}}
</style>
</head>
<body>
<div class="page">
  <div class="folio">Folio interno: $folio</div>
  <div class="encabezado">
    <h1>$(Escape-Html $script:ReportTitle)</h1>
    <p class="desc">$(Escape-Html $script:ReportDescription)</p>
  </div>

  <table class="datos-generales">
    <tr><td class="et">Categoria evaluada</td><td>$(Escape-Html $script:ReportCategory)</td></tr>
    <tr><td class="et">Proyecto evaluado</td><td>$(Escape-Html $script:ProjectRoot)</td></tr>
    <tr><td class="et">Fecha de ejecucion</td><td>$(Escape-Html $ended)</td></tr>
    <tr><td class="et">Duracion del proceso</td><td>$(Escape-Html $duration.ToString())</td></tr>
  </table>

  <h2 class="tit">1. Resumen de resultados</h2>
  <table class="resumen-tabla">
    <tr><th>Criterios evaluados</th><th>Aprobados</th><th>Fallos</th><th>Advertencias</th></tr>
    <tr><td>$total</td><td>$passed</td><td>$failed</td><td>$warnings</td></tr>
  </table>
  <div class="conclusion">$(Escape-Html $conclusion)</div>

  <h2 class="tit">2. Detalle de verificaciones</h2>
  <table class="detalle">
    <thead><tr><th style="width:20%">Criterio</th><th style="width:11%">Estado</th><th style="width:23%">Detalle</th><th style="width:26%">Evidencia</th><th style="width:20%">Recomendacion</th></tr></thead>
    <tbody>
    $($rows.ToString())
    </tbody>
  </table>

  <div class="pie">Reporte generado automaticamente por el script de pruebas correspondiente a esta categoria. Conservar como evidencia de la ejecucion.</div>
</div>
</body>
</html>
"@

    $folder = Split-Path -Parent $OutFile
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Force -Path $folder | Out-Null }
    [System.IO.File]::WriteAllText($OutFile, $html, [System.Text.Encoding]::UTF8)
    Write-Host "Reporte generado:" $OutFile -ForegroundColor Green
}
