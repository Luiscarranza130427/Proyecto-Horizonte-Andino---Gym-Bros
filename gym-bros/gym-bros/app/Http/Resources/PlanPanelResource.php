<?php

namespace App\Http\Resources;

use App\Services\Alimentacion\CalculadorPorcionesService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanPanelResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $usuario = $this->usuario;
        $empresa = $usuario?->empresa;
        $comidas = $this->comidas->map(fn ($comida) => (new ComidaPanelResource($comida))->resolve($request))->all();

        return ['id' => $this->id, 'usuario' => $usuario ? ['id' => $usuario->id,
            'nombre' => trim($usuario->nombres.' '.$usuario->apellidos)] : null,
            'empresa' => $empresa ? ['id' => $empresa->id, 'nombre' => $empresa->nombre] : null,
            'objetivo' => $this->objetivo, 'fecha_inicio' => $this->fecha_inicio, 'fecha_fin' => $this->fecha_fin,
            'activo' => (bool) $this->estado, 'calorias_objetivo' => $this->calorias_objetivo,
            'proteinas_objetivo' => $this->proteinas_objetivo, 'carbohidratos_objetivo' => $this->carbohidratos_objetivo,
            'grasas_objetivo' => $this->grasas_objetivo, 'comidas_count' => count($comidas), 'comidas' => $comidas,
            'macros' => app(CalculadorPorcionesService::class)->sumar(array_column($comidas, 'macros'))];
    }
}
