# DevWebCamp - versión ligera para compartir

Esta carpeta fue limpiada para reducir peso. No incluye dependencias generables ni archivos locales.

## Se eliminó del ZIP
- `node_modules/` -> se regenera con `npm install`
- `vendor/` -> se regenera con `composer install`
- `.git/` -> historial local de Git, no necesario para ejecutar
- `public/build/` -> CSS/JS/imágenes compiladas por Gulp; se regeneran con `npm run dev`
- `.DS_Store` -> archivos basura de macOS
- `includes/.env` -> configuración/credenciales locales. Usar `includes/.env.example` y renombrar a `.env`.

## Se conservó
- `package.json` y `package-lock.json`
- `composer.json` y `composer.lock`
- `src/`, `controllers/`, `models/`, `views/`, `classes/`, `includes/`, `public/index.php`
- `public/img/`, porque contiene imágenes cargadas/guardadas que no necesariamente se regeneran desde `src/img/`

## Pasos para levantar el proyecto

1. Instalar requisitos en la PC:
   - PHP 8.x
   - Composer
   - Node.js LTS
   - SQL Server local o accesible
   - Extensión `pdo_sqlsrv` habilitada en PHP, porque `includes/database.php` usa `sqlsrv:`

2. Abrir terminal en la carpeta del proyecto:

```bash
cd DevWebCamp_inicio
```

3. Instalar dependencias PHP:

```bash
composer install
```

4. Instalar dependencias frontend:

```bash
npm install
```

5. Crear el archivo de entorno:
   - Copiar `includes/.env.example`
   - Renombrarlo como `includes/.env`
   - Cambiar `DB_HOST`, `DB_NAME` y `HOST` según la PC

6. Compilar assets y dejar Gulp vigilando cambios:

```bash
npm run dev
```

7. En otra terminal, ejecutar el servidor PHP apuntando a `public/`:

```bash
php -S localhost:3000 -t public
```

Luego abrir:

```text
http://localhost:3000
```

## Nota importante
El ZIP original no contiene un respaldo `.sql`. Si la aplicación necesita tablas/datos, se debe exportar la base de datos aparte desde SQL Server y compartir ese archivo con el compañero.
