<?php

namespace App\Http\Resources;

use App\Services\Alimentacion\CalculadorPorcionesService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GeneracionPlanAlimentacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $calculador = app(CalculadorPorcionesService::class);
        $dias = [];
        foreach ($this->comidas->groupBy('dia') as $dia => $comidas) {
            $filas = [];
            foreach ($comidas as $comida) {
                $alimentos = $comida->alimentos->map(fn ($a) => [
                    'id' => $a->id, 'id_alimentos' => $a->id_alimentos,
                    'cantidad' => (float) $a->cantidad, 'unidad' => $a->unidad,
                    'notas' => $a->notas, 'detalle_nutricional' => $a->detalle_nutricional,
                ])->all();
                $fraccion = $this->calculo['distribucion'][$comida->tipo] ?? 0;
                $filas[] = ['id' => $comida->id, 'nombre' => $comida->nombre, 'tipo' => $comida->tipo,
                    'orden' => (int) $comida->orden, 'hora_sugerida' => $comida->hora_sugerida,
                    'objetivos' => array_map(fn ($n) => round($n * $fraccion, 2), $this->calculo['objetivos']),
                    'alimentos' => $alimentos,
                    'totales' => $calculador->sumar(array_column(array_column($alimentos, 'detalle_nutricional'), 'nutrientes'))];
            }
            $dias[] = ['dia' => (int) $dia, 'fecha' => $comidas->first()->fecha, 'comidas' => $filas,
                'totales' => $calculador->sumar(array_column($filas, 'totales'))];
        }

        return ['id' => $this->id, 'id_usuarios' => $this->id_usuarios, 'id_evaluaciones_fisicas' => $this->id_evaluaciones_fisicas,
            'nombre' => $this->nombre, 'objetivo' => $this->objetivo, 'fecha_inicio' => $this->fecha_inicio,
            'fecha_fin' => $this->fecha_fin, 'estado' => (bool) $this->estado, 'calculo' => $this->calculo,
            'dias' => $dias, 'totales_plan' => $calculador->sumar(array_column($dias, 'totales')),
            'advertencias' => ['Estimaciones para seguimiento profesional; no constituyen un plan clinico.',
                'La exclusion depende del catalogo verificado; no garantiza ausencia de contaminacion cruzada.',
                'Se ajustan calorias y macronutrientes; no se garantiza suficiencia de micronutrientes.']];
    }
}
