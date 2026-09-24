<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;


class Ejercicio extends Model
{
    use HasFactory;
    protected $table = 'ejercicios';
    protected $fillable = [
        'nombre',
        'descripcion',
        'tipo',
        'instrucciones',
        'nivel',
        'equipamiento',
        'estado',
        'enlace_video',
        'imagen_ejercicio',
        'id_grupos_musculares',
    ];

    public function grupomuscular()
    {
        return $this->belongsTo(GrupoMuscular::class, 'id_grupos_musculares');
    }

    public function empresa()
    {
        return $this->belongsTo(Empresa::class, 'id_empresas');
    }

    public function empresas()
    {
        return $this->belongsToMany(Empresa::class, 'empresa_ejercicio', 'id_ejercicios', 'id_empresas')
            ->withPivot('estado')->withTimestamps();
    }

    public function gruposMusculares()
    {
        return $this->belongsToMany(GrupoMuscular::class, 'ejercicios_grupo_muscular', 'id_ejercicios', 'id_grupos_musculares')
            ->withTimestamps();
    }

    public function rutinas()
    {
        return $this->belongsToMany(Rutina::class, 'ejercicios_rutina', 'id_ejercicios', 'id_rutinas')
            ->withPivot('dia', 'orden', 'series', 'repeticiones', 'peso', 'descanso_segundos', 'tiempo_segundos', 'notas')
            ->withTimestamps();
    }
}
