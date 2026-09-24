<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Suscripcion extends Model
{
    use HasFactory;
    protected $table = 'suscripciones';
    protected $fillable = [
        'id_empresas',
        'id_planes',
        'fecha_inicio',
        'fecha_fin',
        'estado',
        'renovacion_automatica',
       
    ];

    public function empresa()
    {
        return $this->belongsTo(Empresa::class,'id_empresas');
    }

    public function plan()
    {
        return $this->belongsTo(Plan::class,'id_planes');
    }
}
