<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmpresaResource extends JsonResource
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
            'suscripcion' => $this->whenLoaded('suscripcionAsignada', function () {
                $suscripcion = $this->suscripcionAsignada;

                return ['id' => $suscripcion->id, 'id_empresas' => (int) $suscripcion->id_empresas,
                    'id_planes' => (int) $suscripcion->id_planes, 'fecha_inicio' => $suscripcion->fecha_inicio,
                    'fecha_fin' => $suscripcion->fecha_fin, 'estado' => $suscripcion->estado,
                    'renovacion_automatica' => (bool) $suscripcion->renovacion_automatica];
            }),
            'cantidad_usuarios' => $this->whenCounted('usuarios'),
            'nombre'=>$this->nombre,
            'nombre_gerente'=>$this->nombre_gerente,
            'region'=>$this->region,
            'ruc'=>$this->ruc,
            'enlace_web'=>$this->enlace_web,
            'direccion'=>$this->direccion,
            'telefono'=>$this->telefono,
            'correo'=>$this->correo,
            'estado'=>$this->estado,
            'estado_suscripcion' => $this->whenHas('fecha_fin_suscripcion_activa', function ($fecha) {
                if ($fecha === null || $fecha < today()->toDateString()) {
                    return 'Inactivo';
                }

                return $fecha < today()->addDays(7)->toDateString() ? 'Por Vencer' : 'Activo';
            }),
            'fecha_registro'=>$this->fecha_registro,
            'logo'=>$this->logo,
            'logo_url' => \App\Support\RutaPublica::url($this->logo),
            'color_1'=>$this->color_1,
            'color_2'=>$this->color_2,
            'banner_1'=>$this->banner_1,
            'banner_2'=>$this->banner_2,
            'banner_3'=>$this->banner_3,
            'banner_1_url' => \App\Support\RutaPublica::url($this->banner_1),
            'banner_2_url' => \App\Support\RutaPublica::url($this->banner_2),
            'banner_3_url' => \App\Support\RutaPublica::url($this->banner_3),
            'link_boton_1'=>$this->link_boton_1,
            'link_boton_2'=>$this->link_boton_2,
            'link_boton_3'=>$this->link_boton_3,
            'horario_inicio_lunes'=>$this->horario_inicio_lunes,
            'horario_fin_lunes'=>$this->horario_fin_lunes,
            'horario_inicio_martes'=>$this->horario_inicio_martes,
            'horario_fin_martes'=>$this->horario_fin_martes,
            'horario_inicio_miercoles'=>$this->horario_inicio_miercoles,
            'horario_fin_miercoles'=>$this->horario_fin_miercoles,
            'horario_inicio_jueves'=>$this->horario_inicio_jueves,
            'horario_fin_jueves'=>$this->horario_fin_jueves,
            'horario_inicio_viernes'=>$this->horario_inicio_viernes,
            'horario_fin_viernes'=>$this->horario_fin_viernes,
            'horario_inicio_sabado'=>$this->horario_inicio_sabado,
            'horario_fin_sabado'=>$this->horario_fin_sabado,
            'horario_inicio_domingo'=>$this->horario_inicio_domingo,
            'horario_fin_domingo'=>$this->horario_fin_domingo,
        ];
    }
}
