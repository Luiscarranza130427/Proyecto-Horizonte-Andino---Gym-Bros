<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EjercicioGrupoMuscularResource extends JsonResource
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
            'id_ejercicios'=>$this->id_ejercicios,
            'id_grupos_musculares'=>$this->id_grupos_musculares,
            'ejercicio'=> new EjercicioResource($this->whenLoaded('ejercicio')),
        ];
    }
}
