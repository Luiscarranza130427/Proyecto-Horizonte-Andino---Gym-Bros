<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Pago extends Model
{
    use HasFactory;
    protected $table = 'pagos';
    protected $fillable = [
        'id_empresas',
        'id_suscripciones',
        'monto',
        'moneda',
        'metodo_pago',
        'referencia',
        'estado',
        'fecha_pago'
    ];

    public function empresa()
    {
        return $this->belongsTo(Empresa::class,'id_empresas');   
    }

    public function suscripcion()
    {
        return $this->belongsTo(Suscripcion::class,'id_suscripciones');
    }
}
