<?php

namespace App\Services\Rutina;

use App\Models\EvaluacionFisica;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AnalizadorEvaluacionService
{
    public function analizar(EvaluacionFisica $evaluacion): array
    {
        $perfil = Validator::make($evaluacion->toArray(), [
            'nivel_experiencia' => ['required', Rule::in(array_keys(config('rutinas.experiencia')))],
            'objetivo' => ['required', Rule::in(array_keys(config('rutinas.objetivos')))],
            'actividad_diaria' => ['required', Rule::in(['sedentario', 'activo_ligero', 'moderadamente_activo', 'muy_activo'])],
            'dias_semana' => ['required', 'integer', Rule::in(array_keys(config('rutinas.distribuciones')))],
            'tiempo_sesion_min' => ['required', 'integer', 'min:1', 'max:'.config('rutinas.minutos_maximos')],
            'restricciones' => ['required', Rule::in(['sin-restricciones'])],
            'eleccion_dias' => ['nullable', 'array', 'size:'.$evaluacion->dias_semana],
            'eleccion_dias.*' => ['required', 'string', 'distinct', Rule::in(config('rutinas.dias'))],
            'fecha_evaluacion' => ['required', 'date', 'before_or_equal:today'],
            'edad' => ['required', 'integer', 'between:18,100'],
            'peso' => ['required', 'numeric', 'gt:0'],
            'altura' => ['required', 'numeric', 'gt:0'],
        ], [
            'restricciones.in' => 'Esta restriccion requiere reglas de compatibilidad revisadas por un profesional. No se genero una rutina.',
            'nivel_experiencia.in' => 'Nivel no reconocido o ambiguo. Revise la evaluacion; 4a8anos no se interpreta automaticamente como 4a8meses.',
            'eleccion_dias.size' => 'La cantidad de dias elegidos debe coincidir con dias_semana.',
        ])->validate();

        $perfil['nivel'] = config('rutinas.experiencia.'.$perfil['nivel_experiencia']);
        $perfil['dias_semana'] = (int) $perfil['dias_semana'];
        $perfil['tiempo_sesion_min'] = (int) $perfil['tiempo_sesion_min'];
        $perfil['calendario'] = empty($perfil['eleccion_dias'])
            ? config('rutinas.calendarios.'.$perfil['dias_semana'])
            : array_map(fn ($dia) => array_search($dia, config('rutinas.dias'), true) + 1, $perfil['eleccion_dias']);
        sort($perfil['calendario']);

        if ($perfil['tiempo_sesion_min'] * 60 <= config('rutinas.calentamiento_segundos')) {
            throw ValidationException::withMessages(['tiempo_sesion_min' => 'El tiempo disponible no alcanza para una sesion.']);
        }

        return $perfil;
    }
}
