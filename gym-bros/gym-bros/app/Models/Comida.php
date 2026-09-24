<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Comida extends Model
{
    use HasFactory;
    protected $table = 'comidas';
    protected $fillable = [
        'nombre',
        'tipo',
        'orden',
        'hora_sugerida',
        'notas',
        'id_planes_alimentacion', 'dia', 'fecha'
    ];

    public function alimentos()
    {
        return $this->hasMany(ComidaAlimento::class, 'id_comidas')->orderBy('id');
    }

    public function planalimentacion()
    {
        return $this->belongsTo(PlanAlimentacion::class, 'id_planes_alimentacion');
    }
    
}
