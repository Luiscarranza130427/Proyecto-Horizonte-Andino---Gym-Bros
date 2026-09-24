<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PreferenciaAlimentaria extends Model
{
    use HasFactory;
    protected $table = 'preferencias_alimentarias';
    protected $fillable = [
        'activo', 'tipo',
        'id_usuarios',
        'id_alimentos'
       
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }

    public function alimento()
    {
        return $this->belongsto(Alimento::class,'id_alimentos');
    }
}
