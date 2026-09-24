<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ComidaAlimento extends Model
{
    use HasFactory;
    protected $table = 'comida_alimentos';
    protected $fillable = [
        'cantidad',
        'unidad',
        'notas',
        'id_comidas',
        'id_alimentos', 'detalle_nutricional'
    ];

    protected $casts = ['detalle_nutricional' => 'array'];

    public function comida()
    {
        return $this->belongsTo(Comida::class, 'id_comidas');
    }

    public function alimento()
    {
        return $this->belongsTo(Alimento::class, 'id_alimentos');
    }
}
