<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BannerResource extends JsonResource
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
            'imagen'=>$this->imagen,
            'imagen_url' => \App\Support\RutaPublica::url($this->imagen),
            'contenido_text'=>$this->contenido_text,
            'texto_boton'=>$this->texto_boton,
            'enlace_boton'=>$this->enlace_boton,
        ];
    }
}
