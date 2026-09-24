<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AlimentoResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'activo' => $this->activo,
            'nombre'=> $this->nombre,
            'tipo'=>$this->tipo,
            'calorias'=>$this->calorias,
            'proteinas'=>$this->proteinas,
            'carbohidratos'=>$this->carbohidratos,
            'grasas'=>$this->grasas,
            'fibra'=>$this->fibra,
            'base_unidad' => $this->base_unidad,
            'estado_preparacion' => $this->estado_preparacion,
            'gramos_por_unidad' => $this->gramos_por_unidad,
            'densidad_g_ml' => $this->densidad_g_ml,
            'fuente_nutricional' => $this->fuente_nutricional,
            'nutricion_verificada' => $this->nutricion_verificada,
            'restricciones_verificadas' => $this->restricciones_verificadas,
            'grupo_menu' => $this->grupo_menu,
            'tipos_comida' => $this->tipos_comida,
            'porcion_min' => $this->porcion_min,
            'porcion_max' => $this->porcion_max,
            'paso_porcion' => $this->paso_porcion,


        

        ];
    }
}
