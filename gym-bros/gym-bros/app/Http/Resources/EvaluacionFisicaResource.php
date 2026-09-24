<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EvaluacionFisicaResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $diasGuardados = $this->resource->getRawOriginal('eleccion_dias');
        $diasJson = is_string($diasGuardados) ? json_decode($diasGuardados, true) : null;

        return [
            'id'=>$this->id,
            'nivel_experiencia'=>$this->nivel_experiencia,
            'actividad_diaria'=>$this->actividad_diaria,
            'objetivo'=>$this->objetivo,
            'edad'=>$this->edad,
            'peso'=>$this->peso,
            'altura'=>$this->altura,
            'porcentaje_grasa'=>$this->porcentaje_grasa,
            'masa_muscular'=>$this->masa_muscular,
            'cintura'=>$this->cintura,
            'pecho'=>$this->pecho,
            'brazo'=>$this->brazo,
            'muslo'=>$this->muslo,
            'cadera'=>$this->cadera,
            'dias_semana'=>$this->dias_semana,
            'eleccion_dias'=>is_array($diasJson) ? $diasJson : $diasGuardados,
            'tiempo_sesion_min'=>$this->tiempo_sesion_min,
            'restricciones'=>$this->restricciones,
            'fecha_evaluacion'=>$this->fecha_evaluacion,
        ];
    }
}
