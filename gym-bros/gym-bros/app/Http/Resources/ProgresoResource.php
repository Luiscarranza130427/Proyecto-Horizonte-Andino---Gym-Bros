<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProgresoResource extends JsonResource
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
            'peso'=>$this->peso,
            'altura'=>$this->altura,
            'porcentaje_grasa'=>$this->porcentaje_grasa,
            'masa_muscular'=>$this->masa_muscular,
            'cintura'=>$this->cintura,
            'pecho'=>$this->pecho,
            'brazo'=>$this->brazo,
            'muslo'=>$this->muslo,
            'cadera'=>$this->cadera,
            'notas'=>$this->notas,
            'id_usuarios'=>$this->id_usuarios,
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
        ];
    }
}
