<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HistorialCambio extends Model
{
    use HasFactory;
    protected $table = 'historial_cambios';
    protected $fillable = [
        'id_empresas',
        'id_usuarios',
        'tabla_afectada',
        'id_registros',
        'accion',
        'datos_anteriores',
        'datos_nuevos',
        'descripcion'
    ];

    public function empresa()
    {
        return $this->belongsTo(Empresa::class,'id_empresas');

    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }
}
