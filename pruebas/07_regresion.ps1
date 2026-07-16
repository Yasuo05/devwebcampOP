param([string]$ProjectPath = ".", [string]$BaseUrl = "http://localhost:3000")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\07_reporte_regresion.html"
Initialize-QualityReport -Titulo "07. Reporte de regresion" -Descripcion "Reejecuta una matriz corta de rutas criticas para verificar que cambios recientes no hayan roto funcionalidades previamente estables." -Categoria "Regresion" -ProjectPath $root

function Check-Url([string]$Path, [string]$Name) {
    $url = $BaseUrl.TrimEnd('/') + $Path
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 0
    $msg = ""
    try {
        $res = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
        $status = [int]$res.StatusCode
        $msg = "Respuesta recibida. Caracteres: $($res.Content.Length)"
    } catch {
        if ($_.Exception.Response -ne $null) { try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = 0 } }
        $msg = $_.Exception.Message
    }
    $sw.Stop()
    $ok = ($status -ge 200 -and $status -lt 400)
    $estado = if ($ok) { "APROBADO" } else { "FALLO" }
    $detalle = "Ruta critica revisada como parte de regresion. HTTP obtenido: $status."
    $evidencia = "URL: $url`nHTTP: $status`nTiempo: $($sw.ElapsedMilliseconds) ms`n$msg"
    $recomendacion = if ($ok) { "Mantener esta ruta dentro de la matriz de regresion despues de cada cambio." } else { "Revisar el cambio reciente que pudo afectar esta funcionalidad." }
    Add-QualityCheck $Name $estado "Alta" $detalle $evidencia $recomendacion
}

Check-Url "/" "Regresion: inicio publico"
Check-Url "/login" "Regresion: formulario de login"
Check-Url "/registro" "Regresion: formulario de registro"
Check-Url "/paquetes" "Regresion: paquetes"
Check-Url "/workshops-conferencias" "Regresion: conferencias"
Check-Url "/devwebcamp" "Regresion: pagina informativa del evento"

Write-QualityHtmlReport -OutFile $out
