<?php

try {
    // Cargar variables de entorno desde la carpeta includes
    require_once __DIR__ . '/../vendor/autoload.php';

    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->safeLoad();

    // Validar variables necesarias
    $host = $_ENV['DB_HOST'] ?? '';
    $nombreBaseDatos = $_ENV['DB_NAME'] ?? '';

    if ($host === '' || $nombreBaseDatos === '') {
        throw new RuntimeException(
            'Faltan DB_HOST o DB_NAME en el archivo .env'
        );
    }

    // Conexión con Autenticación de Windows
    $db = new PDO(
        "sqlsrv:Server=$host;Database=$nombreBaseDatos",
        null,
        null,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );

    // Consulta temporal para verificar conexión e identidad utilizada
    $stmt = $db->query("
        SELECT 
            GETDATE() AS FechaActual,
            SUSER_SNAME() AS UsuarioConexion,
            DB_NAME() AS BaseActual
    ");

    $resultado = $stmt->fetch();

    /*
    echo '<pre>';
    print_r($resultado);
    echo '</pre>';
    */

} catch (Throwable $e) {
    exit(
        'Error de conexión: ' . $e->getMessage()
        . '<br>Código de error: ' . $e->getCode()
        . '<br>Detalles de conexión:'
        . '<br>Servidor: ' . ($_ENV['DB_HOST'] ?? 'No definido')
        . '<br>Base de datos: ' . ($_ENV['DB_NAME'] ?? 'No definida')
        . '<br>Autenticación: Windows'
    );
}