<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ComidaAlimentoResource extends JsonResource
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
            'cantidad'=>$this->cantidad,
            'unidad'=>$this->unidad,
            'notas'=>$this->notas,
            'id_comidas'=>$this->id_comidas,
            'id_alimentos'=>$this->id_alimentos,
            'comida'=> new ComidaResource($this->whenLoaded('comida')),
            'alimento'=> new AlimentoResource($this->whenLoaded('alimento')),
        ];
    }
}
