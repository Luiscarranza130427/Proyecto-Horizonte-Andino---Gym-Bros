<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RutinaResource extends JsonResource
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
            'dias_semana'=>$this->dias_semana,
            'duracion_estimada'=>$this->duracion_estimada,
            'fecha_inicio'=>$this->fecha_inicio,
            'fecha_fin'=>$this->fecha_fin,
            'estado'=>$this->estado,
            'id_usuarios'=>$this->id_usuarios,
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
        ];
    }
}
