<?php
// Prueba unitaria separada. Ejecutar desde la raiz del proyecto:
// php .\pruebas\03_unitarias_validaciones.php

$root = realpath(__DIR__ . '/..');
$outDir = $root . DIRECTORY_SEPARATOR . 'reportes';
if (!is_dir($outDir)) { mkdir($outDir, 0777, true); }
$outFile = $outDir . DIRECTORY_SEPARATOR . '03_reporte_unitarias.html';
$started = microtime(true);
$checks = [];

function h($value) { return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }
function add_check($nombre, $estado, $severidad, $detalle, $evidencia, $recomendacion) {
    global $checks;
    $checks[] = compact('nombre','estado','severidad','detalle','evidencia','recomendacion');
}
function status_class($estado) {
    if ($estado === 'APROBADO') return 'ok';
    if ($estado === 'FALLO') return 'fail';
    if ($estado === 'ADVERTENCIA') return 'warn';
    return 'skip';
}
function contains_error($alertas, $fragmento) {
    $errores = $alertas['error'] ?? [];
    foreach ($errores as $e) {
        if (stripos($e, $fragmento) !== false) return true;
    }
    return false;
}
function count_errors($alertas) { return count($alertas['error'] ?? []); }

$activeRecord = $root . DIRECTORY_SEPARATOR . 'models' . DIRECTORY_SEPARATOR . 'ActiveRecord.php';
$usuarioModel = $root . DIRECTORY_SEPARATOR . 'models' . DIRECTORY_SEPARATOR . 'Usuario.php';

if (!file_exists($activeRecord) || !file_exists($usuarioModel)) {
    add_check('Carga de modelos para prueba unitaria', 'FALLO', 'Alta', 'No se encontraron los modelos requeridos.', $activeRecord . "\n" . $usuarioModel, 'Verificar que models/ActiveRecord.php y models/Usuario.php existan.');
} else {
    require_once $activeRecord;
    require_once $usuarioModel;
    add_check('Carga de modelos para prueba unitaria', 'APROBADO', 'Alta', 'Los modelos base fueron cargados sin conectar a la base de datos.', 'ActiveRecord.php y Usuario.php cargados', 'Mantener las validaciones separadas de consultas a BD para facilitar pruebas unitarias.');

    $cases = [];
    $cases[] = ['Login vacio', function() { $u = new Model\Usuario([]); $u->validar(); $a = $u->validarLogin(); return contains_error($a, 'Email') && contains_error($a, 'Password'); }, 'Debe rechazar email y password vacios.'];
    $cases[] = ['Login con email invalido', function() { $u = new Model\Usuario(['email'=>'correo_malo','password'=>'123456']); $u->validar(); $a = $u->validarLogin(); return contains_error($a, 'no válido'); }, 'Debe detectar formato de correo incorrecto.'];
    $cases[] = ['Login valido', function() { $u = new Model\Usuario(['email'=>'usuario@correo.com','password'=>'123456']); $u->validar(); $a = $u->validarLogin(); return count_errors($a) === 0; }, 'Debe permitir credenciales con formato correcto.'];
    $cases[] = ['Registro vacio', function() { $u = new Model\Usuario([]); $u->validar(); $a = $u->validar_cuenta(); return contains_error($a, 'Nombre') && contains_error($a, 'Apellido') && contains_error($a, 'Email') && contains_error($a, 'Password'); }, 'Debe exigir datos obligatorios para crear cuenta.'];
    $cases[] = ['Registro con password corto', function() { $u = new Model\Usuario(['nombre'=>'Ana','apellido'=>'Rios','email'=>'ana@correo.com','password'=>'123','password2'=>'123']); $u->validar(); $a = $u->validar_cuenta(); return contains_error($a, '6 caracteres'); }, 'Debe exigir longitud minima de password.'];
    $cases[] = ['Registro con passwords diferentes', function() { $u = new Model\Usuario(['nombre'=>'Ana','apellido'=>'Rios','email'=>'ana@correo.com','password'=>'123456','password2'=>'654321']); $u->validar(); $a = $u->validar_cuenta(); return contains_error($a, 'diferentes'); }, 'Debe rechazar passwords no coincidentes.'];
    $cases[] = ['Registro valido', function() { $u = new Model\Usuario(['nombre'=>'Ana','apellido'=>'Rios','email'=>'ana@correo.com','password'=>'123456','password2'=>'123456']); $u->validar(); $a = $u->validar_cuenta(); return count_errors($a) === 0; }, 'Debe aceptar una cuenta con datos completos.'];
    $cases[] = ['Validacion directa de email', function() { $u = new Model\Usuario(['email'=>'incorrecto']); $u->validar(); $a = $u->validarEmail(); return contains_error($a, 'no válido'); }, 'Debe validar formato de email en recuperacion o registro.'];
    $cases[] = ['Validacion directa de password', function() { $u = new Model\Usuario(['password'=>'123']); $u->validar(); $a = $u->validarPassword(); return contains_error($a, '6 caracteres'); }, 'Debe rechazar passwords menores a 6 caracteres.'];
    $cases[] = ['Hash seguro de password', function() { $u = new Model\Usuario(['password'=>'123456']); $plain = $u->password; $u->hashPassword(); return $u->password !== $plain && password_verify('123456', $u->password); }, 'Debe almacenar hash y no el texto plano.'];
    $cases[] = ['Creacion de token', function() { $u = new Model\Usuario([]); $u->crearToken(); return !empty($u->token); }, 'Debe generar un token no vacio.'];

    foreach ($cases as $case) {
        [$nombre, $fn, $detalle] = $case;
        try {
            $ok = $fn();
            add_check($nombre, $ok ? 'APROBADO' : 'FALLO', 'Alta', $detalle, $ok ? 'Resultado esperado cumplido.' : 'La condicion esperada no se cumplio.', $ok ? 'Conservar la regla de validacion.' : 'Revisar el metodo del modelo Usuario relacionado con esta validacion.');
        } catch (Throwable $e) {
            add_check($nombre, 'FALLO', 'Alta', $detalle, $e->getMessage(), 'Corregir la excepcion y volver a ejecutar las unitarias.');
        }
    }

    // Advertencia de seguridad especifica: uniqid genera tokens predecibles para escenarios sensibles.
    $source = file_get_contents($usuarioModel);
    if (strpos($source, 'uniqid(') !== false) {
        add_check('Robustez del token de usuario', 'ADVERTENCIA', 'Media', 'El modelo genera token con uniqid(). Funciona, pero no es la opcion mas fuerte para seguridad.', 'models/Usuario.php -> crearToken() usa uniqid()', 'Para seguridad mayor, reemplazar por bin2hex(random_bytes(16)).');
    } else {
        add_check('Robustez del token de usuario', 'APROBADO', 'Media', 'No se detecto uso de uniqid() en el token del usuario.', 'Sin hallazgos', 'Mantener generacion criptograficamente segura.');
    }
}

$total = count($checks);
$passed = count(array_filter($checks, fn($c) => $c['estado'] === 'APROBADO'));
$failed = count(array_filter($checks, fn($c) => $c['estado'] === 'FALLO'));
$warnings = count(array_filter($checks, fn($c) => $c['estado'] === 'ADVERTENCIA'));
$skipped = count(array_filter($checks, fn($c) => $c['estado'] === 'NO EJECUTADO'));
$duration = round(microtime(true) - $started, 2);
$conclusion = $failed > 0 ? 'Hay pruebas unitarias fallidas que deben corregirse en los metodos de validacion.' : ($warnings > 0 ? 'Las validaciones principales pasaron, pero existen advertencias tecnicas que conviene mejorar.' : 'Las validaciones unitarias principales fueron aprobadas.');
$rows = '';
foreach ($checks as $c) {
    $class = status_class($c['estado']);
    $rows .= '<tr><td><strong>'.h($c['nombre']).'</strong><span class="small">Severidad: '.h($c['severidad']).'</span></td><td><span class="estado '.$class.'">'.h($c['estado']).'</span></td><td>'.h($c['detalle']).'</td><td><pre>'.h($c['evidencia']).'</pre></td><td>'.h($c['recomendacion']).'</td></tr>';
}
$folio = 'PS-' . date('Ymd-Hi');
$html = <<<HTML
<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>03. Reporte de pruebas unitarias</title><style>
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
</style></head><body>
<div class="page">
  <div class="folio">Folio interno: {$folio}</div>
  <div class="encabezado">
    <h1>03. Reporte de pruebas unitarias</h1>
    <p class="desc">Valida reglas pequenas del modelo Usuario sin depender de navegador ni base de datos.</p>
  </div>
  <table class="datos-generales">
    <tr><td class="et">Categoria evaluada</td><td>Unitarias</td></tr>
    <tr><td class="et">Proyecto evaluado</td><td>@{h(\$root)}</td></tr>
    <tr><td class="et">Duracion del proceso</td><td>{$duration} s</td></tr>
  </table>
  <h2 class="tit">1. Resumen de resultados</h2>
  <table class="resumen-tabla">
    <tr><th>Criterios evaluados</th><th>Aprobados</th><th>Fallos</th><th>Advertencias</th></tr>
    <tr><td>$total</td><td>$passed</td><td>$failed</td><td>$warnings</td></tr>
  </table>
  <div class="conclusion">@{h(\$conclusion)}</div>
  <h2 class="tit">2. Detalle de verificaciones</h2>
  <table class="detalle">
    <thead><tr><th style="width:20%">Criterio</th><th style="width:11%">Estado</th><th style="width:23%">Detalle</th><th style="width:26%">Evidencia</th><th style="width:20%">Recomendacion</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
  <div class="pie">Reporte generado automaticamente por el script de pruebas correspondiente a esta categoria. Conservar como evidencia de la ejecucion.</div>
</div>
</body></html>
HTML;
$html = str_replace('@{h($root)}', h($root), $html);
$html = str_replace('@{h($conclusion)}', h($conclusion), $html);
file_put_contents($outFile, $html);
echo "Reporte generado: $outFile" . PHP_EOL;
