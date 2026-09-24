<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class GrupoMuscular extends Model
{
    use HasFactory;
    protected $table = 'grupos_musculares';
    protected $fillable = [
        'descripcion',
        'estado',
        'tipo'
    ];

    public function ejercicios()
    {
        return $this->belongsToMany(Ejercicio::class, 'ejercicios_grupo_muscular', 'id_grupos_musculares', 'id_ejercicios')
            ->withTimestamps();
    }
}
