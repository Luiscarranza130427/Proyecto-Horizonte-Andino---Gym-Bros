<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanAlimentacionResource extends JsonResource
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
            'descripcion'=>$this->descripcion,
            'objetivo'=>$this->objetivo,
            'calorias_objetivo'=>$this->calorias_objetivo,
            'proteinas_objetivo'=>$this->proteinas_objetivo,
            'carbohidratos_objetivo'=>$this->carbohidratos_objetivo,
            'grasas_objetivo'=>$this->grasas_objetivo,
            'fecha_inicio'=>$this->fecha_inicio,
            'fecha_fin'=>$this->fecha_fin,
            'estado'=>$this->estado,
            'id_usuarios'=>$this->id_usuarios,
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
        ];
    }
}
