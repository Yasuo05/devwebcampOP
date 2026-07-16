param(
    [string]$ProjectPath = ".",
    [int]$UsuariosEvaluados = 0,
    [double]$SUSPromedio = -1,
    [double]$ErroresPromedio = -1,
    [double]$CompletitudPorcentaje = -1
)
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "lib\reporte.ps1")
$root = (Resolve-Path $ProjectPath).Path
$out = Join-Path $root "reportes\09_reporte_usabilidad_aceptacion.html"
Initialize-QualityReport -Titulo "09. Reporte de usabilidad y aceptacion" -Descripcion "Genera evidencia de aceptacion de usuario final. Puede ejecutarse como plantilla o con resultados numericos reales." -Categoria "Usabilidad / Aceptacion" -ProjectPath $root

if ($UsuariosEvaluados -le 0) {
    Add-QualityCheck "Usuarios evaluados" "NO EJECUTADO" "Alta" "No se ingreso cantidad de usuarios evaluados." "Parametro recibido: $UsuariosEvaluados" "Ejecutar nuevamente agregando -UsuariosEvaluados 3 o el numero real de participantes."
} else {
    Add-QualityCheck "Usuarios evaluados" "APROBADO" "Alta" "Se registro cantidad de usuarios participantes en la prueba." "Usuarios: $UsuariosEvaluados" "Conservar firmas, capturas o evidencias de la sesion de prueba."
}

if ($SUSPromedio -lt 0) {
    Add-QualityCheck "Satisfaccion SUS" "NO EJECUTADO" "Alta" "No se ingreso puntaje SUS promedio." "Parametro no informado" "Aplicar la escala SUS y ejecutar con -SUSPromedio 70 o el valor obtenido."
} elseif ($SUSPromedio -ge 70) {
    Add-QualityCheck "Satisfaccion SUS" "APROBADO" "Alta" "El puntaje SUS cumple la meta minima de 70 puntos." "SUS promedio: $SUSPromedio" "Mantener o mejorar los elementos de interfaz valorados por los usuarios."
} else {
    Add-QualityCheck "Satisfaccion SUS" "FALLO" "Alta" "El puntaje SUS esta por debajo de la meta minima." "SUS promedio: $SUSPromedio" "Mejorar textos, navegacion, formularios y claridad visual."
}

if ($ErroresPromedio -lt 0) {
    Add-QualityCheck "Errores promedio por tarea" "NO EJECUTADO" "Media" "No se ingreso promedio de errores por tarea." "Parametro no informado" "Registrar errores de usuario durante tareas clave y ejecutar con -ErroresPromedio 1.5, por ejemplo."
} elseif ($ErroresPromedio -le 2) {
    Add-QualityCheck "Errores promedio por tarea" "APROBADO" "Media" "El promedio de errores esta dentro de la meta maxima de 2 errores por tarea." "Errores promedio: $ErroresPromedio" "Mantener ayudas visuales y validaciones claras."
} else {
    Add-QualityCheck "Errores promedio por tarea" "FALLO" "Media" "El promedio de errores supera la meta definida." "Errores promedio: $ErroresPromedio" "Revisar campos, mensajes de error y flujo de navegacion."
}

if ($CompletitudPorcentaje -lt 0) {
    Add-QualityCheck "Completitud de tareas" "NO EJECUTADO" "Alta" "No se ingreso porcentaje de tareas completadas." "Parametro no informado" "Medir tareas como iniciar sesion, consultar evento, registrarse y finalizar flujo."
} elseif ($CompletitudPorcentaje -ge 90) {
    Add-QualityCheck "Completitud de tareas" "APROBADO" "Alta" "La completitud de tareas cumple el objetivo minimo de 90%." "Completitud: $CompletitudPorcentaje%" "Mantener esta metrica en futuras versiones."
} else {
    Add-QualityCheck "Completitud de tareas" "FALLO" "Alta" "La completitud esta por debajo del objetivo esperado." "Completitud: $CompletitudPorcentaje%" "Identificar en que pasos los usuarios abandonan o fallan."
}

$tasks = "Tareas sugeridas para aplicar manualmente:`n1. Ingresar a la pagina principal.`n2. Consultar informacion del evento.`n3. Revisar paquetes.`n4. Entrar al formulario de registro.`n5. Intentar iniciar sesion con credenciales invalidas y verificar mensaje.`n6. Completar registro con datos validos en ambiente de prueba."
Add-QualityCheck "Matriz de tareas de aceptacion" "APROBADO" "Media" "Se incluye una matriz base de tareas para validar con usuarios finales." $tasks "Usar esta matriz durante la sustentacion o con miembros de la asociacion."

Write-QualityHtmlReport -OutFile $out
