<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanResource extends JsonResource
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
            'precio_original'=>$this->precio_original,
            'precio_inicial'=>$this->precio_inicial,
            'duracion_dias'=>$this->duracion_dias,
            'limite_usuarios'=>$this->limite_usuarios,
            'activo'=>$this->activo,
            'contenido'=>$this->contenido,
            'enlace_whatsapp'=>$this->enlace_whatsapp,
            'created_at'=>$this->created_at,
            'updated_at'=>$this->updated_at,
        ];
    }
}
