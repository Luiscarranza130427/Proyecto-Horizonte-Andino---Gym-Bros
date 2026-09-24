<?php

namespace App\Http\Requests;

class GenerarPlanAlimentacionRequest extends SolicitudAlimentacionRequest
{
    public function rules(): array
    {
        $comidas = config('alimentacion.distribuciones');
        $cantidad = $this->input('cantidad_comidas');
        $tipos = is_scalar($cantidad) ? array_keys($comidas[$cantidad] ?? []) : [];

        return [
            'fecha_inicio' => ['required', 'date_format:Y-m-d', 'after_or_equal:today', 'before_or_equal:'.today()->addDays(30)->toDateString()],
            'duracion_dias' => ['required', 'integer', 'between:1,'.config('alimentacion.max_dias')],
            'cantidad_comidas' => ['required', 'integer', 'in:'.implode(',', array_keys($comidas))],
            'horarios' => ['required', 'array:'.implode(',', $tipos), 'size:'.count($tipos)],
            'horarios.*' => ['required', 'date_format:H:i', 'distinct'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }
            $anterior = '';
            foreach (array_keys(config('alimentacion.distribuciones.'.$this->input('cantidad_comidas'))) as $tipo) {
                $hora = $this->input('horarios.'.$tipo);
                if ($hora === null || $hora <= $anterior) {
                    $validator->errors()->add('horarios', 'Indique todos los horarios en orden cronologico.');
                    break;
                }
                $anterior = $hora;
            }
        }];
    }
}
