<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PreferenciaAlimentariaResource extends JsonResource
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
            'activo'=>$this->activo,
            'id_usuarios'=>$this->id_usuarios,
            'id_alimentos'=>$this->id_alimentos,
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
            'alimento'=> new AlimentoResource($this->whenLoaded('alimento')),
        ];
    }
}
