param([string]$ProjectPath = ".")
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\05_reporte_seguridad.html"
Initialize-QualityReport -Titulo "05. Reporte de seguridad estatica" -Descripcion "Busca patrones de riesgo en el codigo fuente: entradas no controladas, tokens debiles, redirecciones incompletas y exposicion de configuracion." -Categoria "Seguridad" -ProjectPath $root

$phpFiles = Get-ChildItem -Path $root -Recurse -Filter *.php -File | Where-Object { $_.FullName -notmatch "\\vendor\\|\\node_modules\\" }

function Find-Pattern([string]$Pattern) {
    return Select-String -Path $phpFiles.FullName -Pattern $Pattern -ErrorAction SilentlyContinue
}
function Format-Matches($matches, [int]$Max = 25) {
    if ($null -eq $matches -or @($matches).Count -eq 0) { return "Sin hallazgos" }
    return (($matches | Select-Object -First $Max | ForEach-Object { "$($_.Path):$($_.LineNumber) -> $($_.Line.Trim())" }) -join "`n")
}

$envPath = Join-Path $root "includes\.env"
if (Test-Path $envPath) {
    Add-QualityCheck "Archivo .env dentro del proyecto" "ADVERTENCIA" "Alta" "El archivo .env existe dentro de includes. En produccion no debe compartirse con credenciales reales." $envPath "Usar .env.example para compartir y excluir .env con .gitignore."
} else {
    Add-QualityCheck "Archivo .env dentro del proyecto" "APROBADO" "Alta" "No se encontro .env compartido dentro del proyecto." $envPath "Mantener credenciales fuera del paquete entregable."
}

$directInput = Find-Pattern '\$_(GET|POST|REQUEST|COOKIE)'
if ($null -eq $directInput -or @($directInput).Count -eq 0) {
    Add-QualityCheck "Entradas directas del usuario" "APROBADO" "Alta" "No se detecto uso directo de variables globales de entrada." "Sin hallazgos" "Mantener validacion centralizada de entradas."
} else {
    Add-QualityCheck "Entradas directas del usuario" "ADVERTENCIA" "Alta" "Se detectaron accesos directos a GET/POST/REQUEST/COOKIE. No siempre es falla, pero requiere validacion." (Format-Matches $directInput 30) "Validar, sanear y tipar los datos antes de usarlos en consultas o decisiones."
}

$weakTokens = Find-Pattern 'uniqid\(|md5\(|rand\(|mt_rand\('
if ($null -eq $weakTokens -or @($weakTokens).Count -eq 0) {
    Add-QualityCheck "Generacion de tokens aleatorios" "APROBADO" "Media" "No se detectaron funciones debiles comunes." "Sin hallazgos" "Usar random_bytes para tokens sensibles."
} else {
    Add-QualityCheck "Generacion de tokens aleatorios" "ADVERTENCIA" "Media" "Se detectaron funciones predecibles o antiguas para tokens/aleatorios." (Format-Matches $weakTokens 30) "Reemplazar tokens sensibles por bin2hex(random_bytes(16)) o equivalente."
}

$csrf = Find-Pattern "csrf|CSRF|token_csrf"
if ($null -eq $csrf -or @($csrf).Count -eq 0) {
    Add-QualityCheck "Proteccion CSRF en formularios" "ADVERTENCIA" "Alta" "No se detecto evidencia clara de tokens CSRF." "Busqueda: csrf, CSRF, token_csrf" "Agregar token CSRF en formularios POST criticos."
} else {
    Add-QualityCheck "Proteccion CSRF en formularios" "APROBADO" "Alta" "Se detectaron referencias a CSRF o tokens equivalentes." (Format-Matches $csrf 15) "Verificar que se validen en servidor."
}

$passwordHash = Find-Pattern 'password_hash\('
$passwordVerify = Find-Pattern 'password_verify\('
if (($null -ne $passwordHash -and @($passwordHash).Count -gt 0) -and ($null -ne $passwordVerify -and @($passwordVerify).Count -gt 0)) {
    Add-QualityCheck "Manejo de contrasenias" "APROBADO" "Alta" "Se detecto uso de password_hash y password_verify." (Format-Matches $passwordHash 10) "Mantener hashing seguro de contrasenias."
} else {
    Add-QualityCheck "Manejo de contrasenias" "ADVERTENCIA" "Alta" "No se detectaron ambos metodos password_hash/password_verify." "password_hash: $(@($passwordHash).Count)`npassword_verify: $(@($passwordVerify).Count)" "Usar funciones nativas de PHP para contrasenias."
}

$prepare = Find-Pattern '->prepare\('
if ($null -ne $prepare -and @($prepare).Count -gt 0) {
    Add-QualityCheck "Consultas preparadas" "APROBADO" "Alta" "Se detecta uso de prepare() en consultas." "Coincidencias: $(@($prepare).Count)" "Mantener bindParam o parametros para entradas de usuario."
} else {
    Add-QualityCheck "Consultas preparadas" "ADVERTENCIA" "Alta" "No se detecto uso de prepare()." "Sin coincidencias" "Usar consultas preparadas para reducir riesgo de inyeccion SQL."
}

$exceptionLeak = Find-Pattern 'getMessage\(\)'
if ($null -eq $exceptionLeak -or @($exceptionLeak).Count -eq 0) {
    Add-QualityCheck "Exposicion de errores internos" "APROBADO" "Media" "No se detecto salida directa de mensajes de excepcion." "Sin hallazgos" "Registrar errores internamente sin mostrarlos al usuario final."
} else {
    Add-QualityCheck "Exposicion de errores internos" "ADVERTENCIA" "Media" "Se detecto getMessage(). Puede exponer informacion tecnica si se imprime al usuario." (Format-Matches $exceptionLeak 25) "Usar logs internos y mensajes genericos en pantalla."
}

$headerMatches = Find-Pattern 'header\([''"]Location:'
$badHeaders = @()
foreach ($m in $headerMatches) {
    $lines = Get-Content $m.Path
    $start = [Math]::Max(0, $m.LineNumber - 1)
    $end = [Math]::Min($lines.Count - 1, $m.LineNumber + 2)
    $chunk = ($lines[$start..$end] -join " `n")
    if ($chunk -notmatch "exit\s*;|return\s*;") { $badHeaders += "$($m.Path):$($m.LineNumber) -> $($m.Line.Trim())" }
}
if (@($badHeaders).Count -eq 0) {
    Add-QualityCheck "Redirecciones con corte de ejecucion" "APROBADO" "Media" "No se detectaron redirecciones Location sin exit/return cercano." "Redirecciones revisadas: $(@($headerMatches).Count)" "Mantener exit o return despues de redirigir."
} else {
    Add-QualityCheck "Redirecciones con corte de ejecucion" "ADVERTENCIA" "Media" "Hay redirecciones que podrian seguir ejecutando codigo despues del header." ($badHeaders -join "`n") "Agregar exit; o return; despues de header('Location: ...')."
}

Write-QualityHtmlReport -OutFile $out
