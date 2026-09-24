<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Plan extends Model
{
    use HasFactory;
    protected $table = 'planes';
    protected $fillable = [
        'nombre',
        'descripcion',
        'precio_original',
        'precio_inicial',
        'limite_usuarios',
        'activo',
        'contenido',
        'enlace_whatsapp' 
    ];
}
