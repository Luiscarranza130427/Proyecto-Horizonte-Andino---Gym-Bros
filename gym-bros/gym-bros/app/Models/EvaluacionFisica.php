<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class EvaluacionFisica extends Model
{
    use HasFactory;
    protected $table = 'evaluaciones_fisicas';
    protected $fillable = [
        'id_usuarios',
        'nivel_experiencia',
        'actividad_diaria',
        'objetivo',
        'edad',
        'peso',
        'altura', 'altura_unidad',
        'porcentaje_grasa',
        'masa_muscular',
        'cintura',
        'pecho',
        'brazo',
        'muslo',
        'cadera',
        'dias_semana',
        'eleccion_dias',
        'tiempo_sesion_min',
        'restricciones',
        'fecha_evaluacion'

    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'id_usuarios');
    }

    public function getEleccionDiasAttribute($value)
    {
        if ($value === null) {
            return null;
        }
        $decoded = json_decode($value, true);

        // Keep historical single-day values readable alongside new JSON arrays.
        return json_last_error() === JSON_ERROR_NONE ? $decoded : [$value];
    }

    public function setEleccionDiasAttribute($value): void
    {
        $this->attributes['eleccion_dias'] = is_array($value) ? json_encode($value, JSON_THROW_ON_ERROR) : $value;
    }
}
