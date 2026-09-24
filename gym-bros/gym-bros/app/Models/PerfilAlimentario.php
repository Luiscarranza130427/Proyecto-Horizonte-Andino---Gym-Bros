<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PerfilAlimentario extends Model
{
    protected $table = 'perfiles_alimentarios';
    protected $fillable = ['id_usuarios', 'sexo_calculo', 'embarazo', 'lactancia',
        'requiere_plan_clinico', 'apto_plan_general', 'revision_profesional', 'revisado_en'];
    protected $casts = ['embarazo' => 'boolean', 'lactancia' => 'boolean',
        'requiere_plan_clinico' => 'boolean', 'apto_plan_general' => 'boolean'];
}
