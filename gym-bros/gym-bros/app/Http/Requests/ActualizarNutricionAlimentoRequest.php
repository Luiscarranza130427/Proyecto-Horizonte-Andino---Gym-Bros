<?php

namespace App\Http\Requests;

class ActualizarNutricionAlimentoRequest extends SolicitudAlimentacionRequest
{
    public function rules(): array
    {
        return [
            'calorias' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'proteinas' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'carbohidratos' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'grasas' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'fibra' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'base_unidad' => ['required', 'in:gramos,mililitros'],
            'estado_preparacion' => ['required', 'string', 'max:100'],
            'gramos_por_unidad' => ['present', 'nullable', 'numeric', 'decimal:0,2', 'gt:0', 'max:999999.99'],
            'densidad_g_ml' => ['present', 'nullable', 'numeric', 'decimal:0,4', 'gt:0', 'max:9999.9999'],
            'fuente_nutricional' => ['required', 'string', 'max:2000'],
            'nutricion_verificada' => ['required', 'boolean'],
            'restricciones_verificadas' => ['sometimes', 'boolean'],
            'grupo_menu' => ['required', 'in:proteina,carbohidrato,grasa,fruta,verdura'],
            'tipos_comida' => ['required', 'array', 'min:1', 'max:5'],
            'tipos_comida.*' => ['required', 'distinct', 'in:'.implode(',', array_keys(config('alimentacion.grupos_comida')))],
            'porcion_min' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:2000'],
            'porcion_max' => ['required', 'numeric', 'decimal:0,2', 'gte:porcion_min', 'max:2000'],
            'paso_porcion' => ['required', 'numeric', 'decimal:0,2', 'between:0.01,2000'],
            'restricciones' => ['sometimes', 'array', 'max:0'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if ($validator->errors()->isEmpty()) {
                $datos = $this->only(array_keys($this->rules()));
                if (! app(\App\Services\Alimentacion\CalculadorPorcionesService::class)->datosValidos($datos)) {
                    $validator->errors()->add('alimento', 'Revise nutrientes, base y limites de porcion: son incoherentes.');
                }
            }
        }];
    }
}
