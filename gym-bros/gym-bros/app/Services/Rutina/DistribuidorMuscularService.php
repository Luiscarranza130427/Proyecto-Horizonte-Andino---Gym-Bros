<?php

namespace App\Services\Rutina;

use Illuminate\Validation\ValidationException;

class DistribuidorMuscularService
{
    public function distribuir(array $perfil): array
    {
        $sesiones = [];
        foreach (config('rutinas.distribuciones.'.$perfil['dias_semana']) as $indice => $bloque) {
            $sesiones[] = ['dia' => $indice + 1, 'dia_semana' => $perfil['calendario'][$indice],
                'grupos' => config('rutinas.bloques.'.$bloque)];
        }

        // Check the recurring weekly calendar, including the Sunday-to-Monday boundary.
        foreach ($sesiones as $a => $sesion) {
            foreach ($sesiones as $b => $otra) {
                if ($a === $b || ! array_intersect($sesion['grupos'], $otra['grupos'])) {
                    continue;
                }
                $distancia = ($otra['dia_semana'] - $sesion['dia_semana'] + 7) % 7;
                if ($distancia < config('rutinas.recuperacion_dias')) {
                    throw ValidationException::withMessages(['eleccion_dias' => 'Los dias elegidos no permiten la recuperacion prevista para esta distribucion.']);
                }
            }
        }

        return $sesiones;
    }
}
