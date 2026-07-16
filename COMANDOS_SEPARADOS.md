

### 01 Entorno

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\01_entorno.ps1 -ProjectPath .
```

Genera:

```text
reportes/01_reporte_entorno.html
```

### 02 Caja blanca

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\02_caja_blanca_sintaxis.ps1 -ProjectPath .
```

Genera:

```text
reportes/02_reporte_caja_blanca.html
```

### 03 Unitarias

```powershell
php .\pruebas\03_unitarias_validaciones.php
```

Genera:

```text
reportes/03_reporte_unitarias.html
```

### 04 Integracion MVC

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\04_integracion_mvc.ps1 -ProjectPath .
```

Genera:

```text
reportes/04_reporte_integracion.html
```

### 05 Seguridad estatica

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\05_seguridad_estatica.ps1 -ProjectPath .
```

Genera:

```text
reportes/05_reporte_seguridad.html
```

### 06 Funcional / caja negra

Primero servidor:

```powershell
php -S localhost:3000 -t public
```

Luego:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\06_funcionales_caja_negra.ps1 -ProjectPath . -BaseUrl http://localhost:3000
```

Genera:

```text
reportes/06_reporte_funcional_caja_negra.html
```

### 07 Regresion

Con servidor activo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\07_regresion.ps1 -ProjectPath . -BaseUrl http://localhost:3000
```

Genera:

```text
reportes/07_reporte_regresion.html
```

### 08 Rendimiento, carga y estres con k6

Con servidor activo y k6 instalado:

```powershell
k6 run -e BASE_URL=http://localhost:3000 .\pruebas\08_rendimiento_carga_estres_k6.js
```

Genera:

```text
reportes/08_reporte_rendimiento_k6.html
```

### 09 Usabilidad y aceptacion

Como plantilla:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\09_usabilidad_aceptacion.ps1 -ProjectPath .
```

Con resultados reales:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas\09_usabilidad_aceptacion.ps1 -ProjectPath . -UsuariosEvaluados 3 -SUSPromedio 75 -ErroresPromedio 1 -CompletitudPorcentaje 95
```

Genera:

```text
reportes/09_reporte_usabilidad_aceptacion.html
```

## 5. Reportes finales esperados

```text
reportes/
  01_reporte_entorno.html
  02_reporte_caja_blanca.html
  03_reporte_unitarias.html
  04_reporte_integracion.html
  05_reporte_seguridad.html
  06_reporte_funcional_caja_negra.html
  07_reporte_regresion.html
  08_reporte_rendimiento_k6.html
  09_reporte_usabilidad_aceptacion.html
```
