<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Rutina extends Model
{
    use HasFactory;
    protected $table = 'rutinas';
    protected $fillable = [
        'nombre',
        'descripcion',
        'objetivo',
        'dias_semana',
        'duracion_estimada',
        'fecha_inicio',
        'fecha_fin',
        'estado',
        'id_usuarios'
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'id_usuarios');
    }

    public function ejerciciosRutina()
    {
        return $this->hasMany(EjercicioRutina::class, 'id_rutinas')->orderBy('dia')->orderBy('orden');
    }

    public function ejercicios()
    {
        return $this->belongsToMany(Ejercicio::class, 'ejercicios_rutina', 'id_rutinas', 'id_ejercicios')
            ->withPivot('dia', 'orden', 'series', 'repeticiones', 'peso', 'descanso_segundos', 'tiempo_segundos', 'notas')
            ->withTimestamps();
    }
}
