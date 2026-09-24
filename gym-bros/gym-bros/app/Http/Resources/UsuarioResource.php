<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UsuarioResource extends JsonResource
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
            'nombres'=>$this->nombres,
            'apellidos'=>$this->apellidos,
            'genero'=>$this->genero,
            'apodo' =>$this->apodo,
            'correo'=>$this->correo,
            'tipo_documento'=>$this->tipo_documento,
            'numero_documento'=>$this->numero_documento,
            'telefono'=>$this->telefono,
            'direccion'=>$this->direccion,
            'foto_perfil'=>$this->foto_perfil,
            'foto_perfil_url' => \App\Support\RutaPublica::url($this->foto_perfil),
            'fecha_registro'=>$this->fecha_registro,
            'fecha_nacimiento'=>$this->fecha_nacimiento,
            'asistencia_semanal'=>$this->asistencia_semanal,
            'inicio_suscripcion' =>$this->inicio_suscripcion,
            'fin_suscripcion'=>$this->fin_suscripcion,
            'tipo_usuario'=>$this->tipo_usuario,
            'estado'=>$this->estado,
            'id_empresas'=>$this->id_empresas,
            'empresa'=> new EmpresaResource($this->whenLoaded('empresa')),
        ];
    }
}
