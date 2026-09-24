<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HistorialCambioResource extends JsonResource
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
            'id_usuarios'=>$this->id_usuarios,
            'tabla_afectada'=>$this->tabla_afectada,
            'id_registros'=>$this->id_registros,
            'accion'=>$this->accion,
            'datos_anteriores'=>$this->datos_anteriores,
            'datos_nuevos'=>$this->datos_nuevos,
            'descripcion'=>$this->descripcion,
            'empresa'=> new EmpresaResource($this->whenLoaded('empresa')),
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
        ];
    }
}
