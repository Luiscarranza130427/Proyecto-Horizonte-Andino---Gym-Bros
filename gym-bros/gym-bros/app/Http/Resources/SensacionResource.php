<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SensacionResource extends JsonResource
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
            'fecha'=>$this->fecha,
            'energia'=>$this->energia,
            'dificultad'=>$this->dificultad,
            'fatiga'=>$this->fatiga,
            'dolor'=>$this->dolor,
            'comentario'=>$this->comentario,
            'id_usuarios'=>$this->id_usuarios,
            'id_rutinas'=>$this->id_rutinas,
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
            'rutina'=> new RutinaResource($this->whenLoaded('rutina')),
        ];
    }
}
