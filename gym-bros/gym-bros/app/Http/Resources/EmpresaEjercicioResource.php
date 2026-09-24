<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmpresaEjercicioResource extends JsonResource
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
            'estado'=>$this->estado,
            'id_empresas'=>$this->id_empresas,
            'id_ejercicios'=>$this->id_ejercicios,
            'comida'=> new ComidaResource($this->whenLoaded('comida')),
            'alimento'=> new AlimentoResource($this->whenLoaded('alimento')),
        ];
    }
}
