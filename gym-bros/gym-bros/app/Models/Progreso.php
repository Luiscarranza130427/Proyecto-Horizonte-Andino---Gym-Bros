<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Progreso extends Model
{
    use HasFactory;
    protected $table = 'progresos';
    protected $fillable = [
        'fecha',
        'peso',
        'altura',
        'porcentaje_grasa',
        'masa_muscular',
        'cintura',
        'pecho',
        'brazo',
        'muslo',
        'cadera',
        'notas',
        'id_usuarios'
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }
}
