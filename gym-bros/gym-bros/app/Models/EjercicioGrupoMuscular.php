<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class EjercicioGrupoMuscular extends Model
{
    use HasFactory;
    protected $table = 'ejercicios_grupo_muscular';
    protected $fillable = [
        'id_ejercicios',
        'id_grupos_musculares',
        
    ];
    public function ejercicio()
    {
        return $this->belongsTo(Ejercicio::class,'id_ejercicios');
    }

    public function grupoMuscular()
    {
        return $this->belongsTo(GrupoMuscular::class, 'id_grupos_musculares');
    }

}
