<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SuscripcionResource extends JsonResource
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
            'id_empresas'=>$this->id_empresas,
            'id_planes'=>$this->id_planes,
            'fecha_inicio'=>$this->fecha_inicio,
            'fecha_fin'=>$this->fecha_fin,
            'estado'=>$this->estado,
            'renovacion_automatica'=>$this->renovacion_automatica,
            'empresa'=> new EmpresaResource($this->whenLoaded('empresa')),
            'plan'=> new PlanResource($this->whenLoaded('plan')),
        ];
    }
}
