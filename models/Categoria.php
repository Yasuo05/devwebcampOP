<?php

namespace Model;

class categoria extends ActiveRecord {
    protected static $tabla = 'categorias';
    protected static $columnasDB = ['id', 'nombre'];



    public $id;
    public $nombre;
}