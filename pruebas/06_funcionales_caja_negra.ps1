param([string]$ProjectPath = ".", [string]$BaseUrl = "http://localhost:3000")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\06_reporte_funcional_caja_negra.html"
Initialize-QualityReport -Titulo "06. Reporte funcional - caja negra HTTP" -Descripcion "Evalua rutas del sistema desde el comportamiento observable: codigo HTTP, tiempo de respuesta y disponibilidad de paginas principales." -Categoria "Funcional / Caja negra" -ProjectPath $root

function Invoke-RouteCheck([string]$Url, [int[]]$ExpectedStatus) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 0
    $message = ""
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 5
        $status = [int]$response.StatusCode
        $message = "Longitud respuesta: $($response.Content.Length) caracteres"
    } catch {
        if ($_.Exception.Response -ne $null) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = 0 }
        }
        $message = $_.Exception.Message
    }
    $sw.Stop()
    $ok = $ExpectedStatus -contains $status
    return [PSCustomObject]@{Ok=$ok; Status=$status; Ms=$sw.ElapsedMilliseconds; Message=$message; Url=$Url; Expected=($ExpectedStatus -join ",")}
}

$routes = @(
    @{Name="Pagina de inicio"; Path="/"; Expected=@(200)},
    @{Name="Pagina del evento"; Path="/devwebcamp"; Expected=@(200)},
    @{Name="Paquetes"; Path="/paquetes"; Expected=@(200)},
    @{Name="Workshops y conferencias"; Path="/workshops-conferencias"; Expected=@(200)},
    @{Name="Login GET"; Path="/login"; Expected=@(200)},
    @{Name="Registro GET"; Path="/registro"; Expected=@(200)},
    @{Name="Olvide password GET"; Path="/olvide"; Expected=@(200)},
    @{Name="Pagina 404 controlada"; Path="/404"; Expected=@(200,404)},
    @{Name="API eventos horario"; Path="/api/eventos-horario"; Expected=@(200,204,302)},
    @{Name="Dashboard protegido"; Path="/admin/dashboard"; Expected=@(200,302,403)}
)

foreach ($r in $routes) {
    $url = $BaseUrl.TrimEnd('/') + $r.Path
    $result = Invoke-RouteCheck -Url $url -ExpectedStatus $r.Expected
    $state = if ($result.Ok) { "APROBADO" } else { "FALLO" }
    $detail = "Se esperaba HTTP $($result.Expected) y se obtuvo HTTP $($result.Status). Tiempo: $($result.Ms) ms."
    $evidence = "URL: $($result.Url)`nEstado HTTP: $($result.Status)`nTiempo: $($result.Ms) ms`nMensaje: $($result.Message)"
    $rec = if ($result.Ok) { "Conservar la ruta operativa y agregarla a regresion." } else { "Levantar el servidor, revisar base de datos, rutas o errores PHP para esta URL." }
    Add-QualityCheck $r.Name $state "Alta" $detail $evidence $rec
}

Write-QualityHtmlReport -OutFile $out
