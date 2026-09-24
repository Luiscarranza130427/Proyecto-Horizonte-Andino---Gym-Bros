<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Empresa extends Model
{
    use HasFactory;
    protected $table = 'empresas';
    protected $fillable = [
        'nombre',
        'nombre_gerente',
        'region',
        'ruc',
        'enlace_web',
        'direccion',
        'telefono',
        'correo',
        'estado',
        'fecha_registro',
        'logo',
        'color_1',
        'color_2',
        'banner_1',
        'banner_2',
        'banner_3',
        'link_boton_1',
        'link_boton_2',
        'link_boton_3',
        'horario_inicio_lunes',
        'horario_fin_lunes',
        'horario_inicio_martes',
        'horario_fin_martes',
        'horario_inicio_miercoles',
        'horario_fin_miercoles',
        'horario_inicio_jueves',
        'horario_fin_jueves',
        'horario_inicio_viernes',
        'horario_fin_viernes',
        'horario_inicio_sabado',
        'horario_fin_sabado',
        'horario_inicio_domingo',
        'horario_fin_domingo'  
    ];

    public function ejercicios()
    {
        return $this->belongsToMany(Ejercicio::class, 'empresa_ejercicio', 'id_empresas', 'id_ejercicios')
            ->withPivot('estado')->withTimestamps();
    }

    public function usuarios()
    {
        return $this->hasMany(Usuario::class, 'id_empresas');
    }

    public function suscripciones()
    {
        return $this->hasMany(Suscripcion::class, 'id_empresas');
    }
}
