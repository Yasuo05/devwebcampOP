<?php

namespace Model;

use PDO;
use PDOException;

class ActiveRecord
{
    // Base de Datos
    protected static $db;
    protected static $tabla = '';
    protected static $columnasDB = [];

    // Alertas y Mensajes
    protected static $alertas = [];

    // Definir la conexión a la BD
    public static function setDB($database)
    {
        self::$db = $database;
    }

    // Setear un tipo de Alerta
    public static function setAlerta($tipo, $mensaje)
    {
        static::$alertas[$tipo][] = $mensaje;
    }

    // Obtener las alertas
    public static function getAlertas()
    {
        return static::$alertas;
    }

    // Validación que se hereda en modelos
    public function validar()
    {
        static::$alertas = [];
        return static::$alertas;
    }

    // Consulta SQL para crear un objeto en Memoria (Active Record)
    public static function consultarSQL($query)
    {
      /* echo "Consulta SQL: " . $query . "\n";  */ // Imprimir la consulta
         try {
            $stmt = self::$db->prepare($query);
            $stmt->execute();
            $registros = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
            if (empty($registros)) {
            }
    
            $array = [];
            foreach ($registros as $registro) {
                $array[] = static::crearObjeto($registro);
            }
            return $array;
        } catch (PDOException $e) {
            return [];
        }
    }
    
    

    // Crea el objeto en memoria que es igual al de la BD
    protected static function crearObjeto($registro)
    {
        $objeto = new static;

        foreach ($registro as $key => $value) {
            if (property_exists($objeto, $key)) {
                $objeto->$key = $value;
            }
        }
        return $objeto;
    }

    // Identificar y unir los atributos de la BD
    public function atributos()
    {
        $atributos = [];
        foreach (static::$columnasDB as $columna) {
            if ($columna === 'id') continue;
            $atributos[$columna] = $this->$columna;
        }
        return $atributos;
    }

    // Sincroniza BD con Objetos en memoria
    public function sincronizar($args = [])
    {
        foreach ($args as $key => $value) {
            if (property_exists($this, $key) && !is_null($value)) {
                $this->$key = $value;
            }
        }
    }

    // Registros - CRUD
    public function guardar()
    {
        $resultado = '';
        if (!is_null($this->id)) {
            // actualizar
            $resultado = $this->actualizar();
        } else {
            // Creando un nuevo registro
            $resultado = $this->crear();
        }
        return $resultado;
    }

    // Obtener todos los Registros
    public static function all($orden = 'DESC')
    {
        $query = "SELECT * FROM " . static::$tabla . " ORDER BY id " . $orden;
        $resultado = self::consultarSQL($query);
        return $resultado;
    }

    // Busca un registro por su id
    public static function find($id)
    {
        $query = "SELECT * FROM " . static::$tabla . " WHERE id = :id";
        try {
            $stmt = self::$db->prepare($query);
            $stmt->bindParam(':id', $id, PDO::PARAM_INT);
            $stmt->execute();
            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return $resultado ? static::crearObjeto($resultado) : null;
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return null;
        }
    }

    // Obtener Registros con cierta cantidad
    public static function get($limite)
    {
        $query = "SELECT TOP " . $limite . " * FROM " . static::$tabla . " ORDER BY id DESC";
        $resultado = self::consultarSQL($query);
        return $resultado;
    }

    // Paginar los registros
    public static function paginar($por_paginar, $offset)
    {
        $query = "SELECT * FROM " . static::$tabla . " ORDER BY id DESC OFFSET " . $offset . " ROWS FETCH NEXT " . $por_paginar . " ROWS ONLY";
        $resultado = self::consultarSQL($query);
        return $resultado;
    }

    // Busqueda Where con Columna 
    public static function where($columna, $valor)
    {
        $query = "SELECT * FROM " . static::$tabla . " WHERE " . $columna . " = :valor";
        try {
            $stmt = self::$db->prepare($query);
            $stmt->bindParam(':valor', $valor);
            $stmt->execute();
            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return $resultado ? static::crearObjeto($resultado) : null;
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return null;
        }
    }

    // Retornar los registros por un orden
    public static function ordenar($columna, $orden)
    {
        $query = "SELECT * FROM " . static::$tabla . " ORDER BY " . $columna . " " . $orden;
        $resultado = self::consultarSQL($query);
        return $resultado;
    }

    // Retornar por orden y con un limite
    public static function ordenarLimite($columna, $orden, $limite)
    {
        $query = "SELECT TOP " . $limite . " * FROM " . static::$tabla . " ORDER BY " . $columna . " " . $orden;
        $resultado = self::consultarSQL($query);
        return $resultado;
    }

    // Busqueda where con multiples opciones
    public static function whereArray($array = [])
    {
        $query = "SELECT * FROM " . static::$tabla . " WHERE ";
        $condiciones = [];
        $params = [];

        foreach ($array as $key => $value) {
            $condiciones[] = $key . " = :" . $key;
            $params[":" . $key] = $value;
        }

        $query .= implode(" AND ", $condiciones);

        try {
            $stmt = self::$db->prepare($query);
            $stmt->execute($params);
            $resultados = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $array = [];
            foreach ($resultados as $registro) {
                $array[] = static::crearObjeto($registro);
            }

            return $array;
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return [];
        }
    }

    // Total de registros
    public static function total($columna = '', $valor = '')
    {
        $query = "SELECT COUNT(*) as total FROM " . static::$tabla;

        if ($columna) {
            $query .= " WHERE " . $columna . " = :valor";
        }

        try {
            $stmt = self::$db->prepare($query);
            
            if ($columna) {
                $stmt->bindParam(':valor', $valor);
            }
            
            $stmt->execute();
            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return $resultado['total'];
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return 0;
        }
    }

    // Total de registros con un array where
    public static function totalArray($array = [])
    {
        $query = "SELECT COUNT(*) as total FROM " . static::$tabla . " WHERE ";
        $condiciones = [];
        $params = [];

        foreach ($array as $key => $value) {
            $condiciones[] = $key . " = :" . $key;
            $params[":" . $key] = $value;
        }

        $query .= implode(" AND ", $condiciones);

        try {
            $stmt = self::$db->prepare($query);
            $stmt->execute($params);
            $resultado = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return $resultado['total'];
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return 0;
        }
    }

    // Crea un nuevo registro
    public function crear()
    {
        // Identificar atributos del objeto
        $atributos = $this->atributos();

        // Construir la consulta
        $columnas = implode(', ', array_keys($atributos));
        $valores = ':' . implode(', :', array_keys($atributos));

        // Consulta SQL
        $query = "INSERT INTO " . static::$tabla . " ($columnas) VALUES ($valores)";

        try {
            $stmt = self::$db->prepare($query);

            // Bindear valores
            foreach ($atributos as $key => $value) {
                $stmt->bindValue(':' . $key, $value);
            }

            // Ejecutar la consulta
            $resultado = $stmt->execute();

            return [
                'resultado' => $resultado,
                'id' => self::$db->lastInsertId()
            ];
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return [
                'resultado' => false,
                'id' => null
            ];
        }
    }

    // Actualizar el registro
    public function actualizar()
    {
        // Sanitizar los datos
        $atributos = $this->atributos();

        // Preparar el array de valores
        $valores = [];
        foreach ($atributos as $key => $value) {
            $valores[] = "$key = :$key";
        }

        // Consulta SQL
        $query = "UPDATE " . static::$tabla . " SET " . implode(', ', $valores) . " WHERE id = :id";

        try {
            $stmt = self::$db->prepare($query);

            // Bindear valores
            foreach ($atributos as $key => $value) {
                $stmt->bindValue(':' . $key, $value);
            }
            $stmt->bindValue(':id', $this->id);

            // Ejecutar la consulta
            $resultado = $stmt->execute();

            return $resultado;
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return false;
        }
    }

    // Eliminar un Registro por su ID
    public function eliminar()
    {
        $query = "DELETE FROM " . static::$tabla . " WHERE id = :id";

        try {
            $stmt = self::$db->prepare($query);
            $stmt->bindValue(':id', $this->id);
            $resultado = $stmt->execute();

            return $resultado;
        } catch (PDOException $e) {
            echo "Error: " . $e->getMessage();
            return false;
        }
    }
}