<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificacionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $datos = $this->datos;
        if (is_array($datos) && isset($datos['imagen_fondo'])) {
            $datos['imagen_fondo_url'] = \App\Support\RutaPublica::url($datos['imagen_fondo']);
        }
        return [
            'id'=>$this->id,
            'id_empresas'=>$this->id_empresas,
            'id_usuarios'=>$this->id_usuarios,
            'tipo'=>$this->tipo,
            'titulo'=>$this->titulo,
            'mensaje'=>$this->mensaje,
            'fecha_envio'=>$this->fecha_envio,
            'leida'=>$this->leida,
            'enviada'=>$this->enviada,
            'datos'=>$datos,
            'nombre_empresa' => $this->whenLoaded('empresa', fn () => $this->empresa?->nombre),
            'created_at' => $this->created_at,
            'empresa'=> new EmpresaResource($this->whenLoaded('empresa')),
            'usuario'=> new UsuarioResource($this->whenLoaded('usuario')),
        ];
    }
}
