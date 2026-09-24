<?php

namespace App\Services\Alimentacion;

use App\Models\EvaluacionFisica;
use App\Models\PerfilAlimentario;
use App\Models\Usuario;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class CalculadorObjetivosService
{
    public function calcular(Usuario $usuario, EvaluacionFisica $evaluacion, PerfilAlimentario $perfil, string $fecha): array
    {
        $fallar = fn ($mensaje) => throw ValidationException::withMessages(['evaluacion' => $mensaje]);
        if (! $perfil->apto_plan_general || $perfil->embarazo || $perfil->lactancia || $perfil->requiere_plan_clinico) {
            $fallar('El perfil requiere atencion profesional; no se genera un plan general.');
        }
        $datos = ['nacimiento' => $usuario->fecha_nacimiento, 'evaluacion' => $evaluacion->fecha_evaluacion];
        if (Validator::make($datos, [
            'nacimiento' => 'required|date_format:Y-m-d|before:today',
            'evaluacion' => 'required|date_format:Y-m-d|before_or_equal:today',
        ])->fails()) {
            $fallar('Revise nacimiento y fecha de evaluacion fisica.');
        }
        $inicio = CarbonImmutable::parse($fecha);
        $nacimiento = CarbonImmutable::parse($usuario->fecha_nacimiento);
        $fechaEvaluacion = CarbonImmutable::parse($evaluacion->fecha_evaluacion);
        $edad = (int) $nacimiento->diffInYears($inicio);
        if ($fechaEvaluacion->lt($nacimiento)
            || (int) $nacimiento->diffInYears($fechaEvaluacion) !== (int) $evaluacion->edad
            || $edad < config('alimentacion.edad_min') || $edad > config('alimentacion.edad_max')
            || $fechaEvaluacion->diffInDays($inicio) > config('alimentacion.vigencia_evaluacion_dias')) {
            $fallar('Edad incoherente, fuera de alcance o evaluacion fisica vencida.');
        }
        if ($evaluacion->altura_unidad !== 'cm'
            || $evaluacion->altura < config('alimentacion.altura_min_cm') || $evaluacion->altura > config('alimentacion.altura_max_cm')
            || $evaluacion->peso < config('alimentacion.peso_min') || $evaluacion->peso > config('alimentacion.peso_max')) {
            $fallar('Verifique altura en centimetros y peso; no se convierten datos historicos automaticamente.');
        }
        $factor = config('alimentacion.factores_actividad.'.$evaluacion->actividad_diaria);
        $regla = config('alimentacion.objetivos.'.$evaluacion->objetivo);
        if (! is_numeric($factor) || $factor <= 0 || ! is_array($regla)
            || ! in_array($perfil->sexo_calculo, ['masculino', 'femenino'], true)) {
            $fallar('Objetivo, actividad o sexo de calculo sin regla disponible.');
        }
        if (abs($regla['proteinas'] + $regla['carbohidratos'] + $regla['grasas'] - 1) > 0.00001
            || min($regla['proteinas'], $regla['carbohidratos'], $regla['grasas']) <= 0) {
            $fallar('Configuracion de nutrientes invalida.');
        }
        // Mifflin-St Jeor (1990), simplified equation: kg, cm and years.
        $reposo = 10 * $evaluacion->peso + 6.25 * $evaluacion->altura - 5 * $edad
            + ($perfil->sexo_calculo === 'masculino' ? 5 : -161);
        $energia = round($reposo * $factor * (1 + $regla['ajuste']), 2);
        if ($energia < $reposo || $energia > 9999.99 || $energia <= 0) {
            $fallar('El objetivo energetico requiere revision profesional.');
        }

        return [
            'objetivos' => ['calorias' => $energia, 'proteinas' => round($energia * $regla['proteinas'] / 4, 2),
                'carbohidratos' => round($energia * $regla['carbohidratos'] / 4, 2), 'grasas' => round($energia * $regla['grasas'] / 9, 2)],
            'formula' => 'Mifflin-St Jeor simplificada', 'edad_calculo' => $edad,
            'peso_kg' => (float) $evaluacion->peso, 'altura_cm' => (float) $evaluacion->altura,
            'sexo_calculo' => $perfil->sexo_calculo, 'reposo_kcal' => round($reposo, 2),
            'factor_actividad' => $factor, 'ajuste_objetivo' => $regla['ajuste'],
            'version' => config('alimentacion.version'), 'tolerancias' => config('alimentacion.tolerancias'),
            'revision_profesional' => $perfil->revision_profesional, 'revisado_en' => $perfil->revisado_en,
        ];
    }
}
