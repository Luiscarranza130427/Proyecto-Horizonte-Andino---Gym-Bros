<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Alimento extends Model
{
    use HasFactory;
    protected $table = 'alimentos';
    protected $fillable = [
        'nombre', 'activo',
        'tipo',
        'calorias',
        'proteinas',
        'carbohidratos',
        'grasas',
        'fibra', 'base_unidad', 'estado_preparacion', 'gramos_por_unidad', 'densidad_g_ml',
        'fuente_nutricional', 'nutricion_verificada', 'restricciones_verificadas',
        'grupo_menu', 'tipos_comida', 'porcion_min', 'porcion_max', 'paso_porcion'
        
    ];
    protected $casts = ['activo' => 'boolean', 'tipos_comida' => 'array', 'nutricion_verificada' => 'boolean', 'restricciones_verificadas' => 'boolean'];
}
