<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EjercicioRutinaResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'=>$this->id,
            'dia'=>$this->dia,
            'orden'=>$this->orden,
            'series'=>$this->series,
            'repeticiones'=>$this->repeticiones,
            'peso'=>$this->peso,
            'descanso_segundos'=>$this->descanso_segundos,
            'tiempo_segundos'=>$this->tiempo_segundos,
            'notas'=>$this->notas,
            'id_rutinas'=>$this->id_rutinas,
            'id_ejercicios'=>$this->id_ejercicios,
            'rutina'=> new RutinaResource($this->whenLoaded('rutina')),
            'ejercicio'=> new EjercicioResource($this->whenLoaded('ejercicio')),
        ];
    }
}
