<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class EjercicioRutina extends Model
{
    use HasFactory;
    protected $table = 'ejercicios_rutina';
    protected $fillable = [
        'dia',
        'orden',
        'series',
        'repeticiones',
        'peso',
        'descanso_segundos',
        'tiempo_segundos',
        'notas',
        'id_rutinas',
        'id_ejercicios'
    ];
    public function rutina()
    {
        return $this->belongsTo(Rutina::class,'id_rutinas');
    }

    public function ejercicio()
    {
        return $this->belongsTo(Ejercicio::class,'id_ejercicios');
    }
}
