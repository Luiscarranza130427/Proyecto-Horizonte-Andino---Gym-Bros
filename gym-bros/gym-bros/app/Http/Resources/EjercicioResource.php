<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EjercicioResource extends JsonResource
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
            'tipo'=>$this->tipo,
            'instrucciones'=>$this->instrucciones,
            'nivel'=>$this->nivel,
            'equipamiento'=>$this->equipamiento,
            'estado'=>$this->estado,
            'estado_empresa' => $this->whenHas('estado_empresa', fn ($estado) => (bool) $estado, null),
            'enlace_video'=>$this->enlace_video,
            'imagen_ejercicio'=>$this->imagen_ejercicio,
            'imagen_url' => \App\Support\RutaPublica::url($this->imagen_ejercicio),
            'id_grupos_musculares'=>$this->id_grupos_musculares,
            'tipo_grupo_muscular' => $this->whenHas('tipo_grupo_muscular'),
            'grupomuscular'=> new GrupoMuscularResource($this->whenLoaded('grupomuscular')),
        ];
    }
}
