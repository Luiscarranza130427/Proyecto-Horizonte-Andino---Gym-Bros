<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PlanAlimentacion extends Model
{
    use HasFactory;
    protected $table = 'planes_alimentacion';
    protected $fillable = [
       'nombre',
       'descripcion',
       'objetivo',
       'calorias_objetivo',
       'proteinas_objetivo',
       'carbohidratos_objetivo',
       'grasas_objetivo',
       'fecha_inicio',
       'fecha_fin',
       'estado',
       'id_usuarios', 'id_evaluaciones_fisicas', 'calculo'
 
    ];

    protected $casts = ['calculo' => 'array'];

    public function comidas()
    {
        return $this->hasMany(Comida::class, 'id_planes_alimentacion')->orderBy('dia')->orderBy('orden');
    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }
}
