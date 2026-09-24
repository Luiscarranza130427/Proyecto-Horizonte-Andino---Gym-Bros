<?php

namespace App\Http\Resources;

use App\Services\Alimentacion\CalculadorPorcionesService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ComidaPanelResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $calculador = app(CalculadorPorcionesService::class);
        $alimentos = $this->alimentos->map(function ($porcion) use ($calculador) {
            $macros = $porcion->detalle_nutricional['nutrientes'] ?? null;
            if ($macros === null && $porcion->alimento?->base_unidad) {
                // Solo es para mostrar: una porcion historica sin conversion
                // posible (p. ej. mililitros sin densidad) no debe tumbar el
                // listado entero con 422. Al guardar se sigue validando estricto.
                try {
                    $macros = $calculador->nutrientes($porcion->alimento->toArray(), (float) $porcion->cantidad, $porcion->unidad);
                } catch (\Illuminate\Validation\ValidationException) {
                    $macros = null;
                }
            }

            return ['id' => $porcion->id, 'alimento' => $porcion->alimento
                ? ['id' => $porcion->alimento->id, 'nombre' => $porcion->alimento->nombre, 'tipo' => $porcion->alimento->tipo] : null,
                'cantidad' => (float) $porcion->cantidad, 'unidad' => $porcion->unidad,
                'macros_calculables' => $macros !== null,
                'macros' => $macros ?? array_fill_keys(CalculadorPorcionesService::NUTRIENTES, 0.0)];
        })->all();

        return ['id' => $this->id, 'tipo_comida' => $this->tipo, 'hora_sugerida' => $this->hora_sugerida,
            'orden' => (int) $this->orden, 'dia' => $this->dia, 'fecha' => $this->fecha,
            'alimentos' => $alimentos, 'macros' => $calculador->sumar(array_column($alimentos, 'macros'))];
    }
}
