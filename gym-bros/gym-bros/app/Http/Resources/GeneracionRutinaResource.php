<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GeneracionRutinaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $rutina = $this->resource['rutina'];
        $ejercicios = EjercicioRutinaResource::collection($rutina->ejerciciosRutina)->resolve($request);

        return (new RutinaResource($rutina))->resolve($request) + [
            'ejercicios' => $ejercicios,
            'sesiones' => array_map(fn ($sesion) => [
                'dia' => $sesion['dia'],
                'dia_semana' => config('rutinas.dias')[$sesion['dia_semana'] - 1],
                'duracion_estimada_segundos' => $sesion['duracion_estimada_segundos'],
                'ejercicios' => array_values(array_filter($ejercicios, fn ($ejercicio) => $ejercicio['dia'] === $sesion['dia'])),
            ], $this->resource['sesiones']),
            'advertencias' => $this->resource['advertencias'],
        ];
    }
}
