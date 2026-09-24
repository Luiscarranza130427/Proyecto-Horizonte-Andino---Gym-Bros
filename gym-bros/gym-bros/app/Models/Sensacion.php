<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Sensacion extends Model
{
    use HasFactory;
    protected $table = 'sensaciones';
    protected $fillable = [
        'fecha',
        'energia',
        'dificultad',
        'fatiga',
        'dolor',
        'comentario',
        'id_usuarios',
        'id_rutinas'
    ];
    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }

    public function rutina()
    {
        return $this->belongsTo(Rutina::class,'id_rutinas');
    }
}


