<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ComidaResource extends JsonResource
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
            'nombre'=>$this->nombre,
            'tipo'=>$this->tipo,
            'orden'=>$this->orden,
            'hora_sugerida'=>$this->hora_sugerida,
            'notas'=>$this->notas,
            'id_planes_alimentacion'=>$this->id_planes_alimentacion,
            'planalimentacion'=> new PlanAlimentacionResource($this->whenLoaded('planalimentacion')),
        ];
    }
}
