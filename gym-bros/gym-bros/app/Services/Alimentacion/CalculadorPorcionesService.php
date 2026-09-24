<?php

namespace App\Services\Alimentacion;

use Illuminate\Validation\ValidationException;

class CalculadorPorcionesService
{
    public const NUTRIENTES = ['calorias', 'proteinas', 'carbohidratos', 'grasas', 'fibra'];

    public function datosValidos(array $a): bool
    {
        foreach (array_merge(self::NUTRIENTES, ['porcion_min', 'porcion_max', 'paso_porcion']) as $campo) {
            if (! isset($a[$campo]) || ! is_numeric($a[$campo]) || ! is_finite((float) $a[$campo]) || $a[$campo] < 0) {
                return false;
            }
        }
        if (! in_array($a['base_unidad'] ?? null, ['gramos', 'mililitros'], true)
            || empty($a['fuente_nutricional']) || empty($a['estado_preparacion'])
            || $a['calorias'] <= 0 || $a['porcion_min'] <= 0 || $a['paso_porcion'] <= 0
            || $a['porcion_max'] > 2000 || $a['porcion_min'] > $a['porcion_max']) {
            return false;
        }
        $macro = $a['proteinas'] + $a['carbohidratos'] + $a['grasas'];
        $energia = 4 * $a['proteinas'] + 4 * $a['carbohidratos'] + 9 * $a['grasas'];
        if (($a['base_unidad'] === 'gramos' && $macro > 101)
            || $a['fibra'] > $a['carbohidratos'] + 0.01
            || abs($a['calorias'] - $energia) > max(25, $energia * 0.20)) {
            return false;
        }

        return ceil(($a['porcion_min'] - 0.00001) / $a['paso_porcion'])
            <= floor(($a['porcion_max'] + 0.00001) / $a['paso_porcion']);
    }

    public function nutrientes(array $alimento, float $cantidad, string $unidad): array
    {
        if (! is_finite($cantidad) || $cantidad <= 0) {
            throw ValidationException::withMessages(['cantidad' => 'La cantidad debe ser positiva y finita.']);
        }
        $base = $alimento['base_unidad'] ?? null;
        if (! in_array($base, ['gramos', 'mililitros'], true)) {
            throw ValidationException::withMessages(['unidad' => 'El alimento no tiene base nutricional verificada.']);
        }
        if ($unidad === 'unidad') {
            $gramos = $alimento['gramos_por_unidad'] ?? null;
            if (! is_numeric($gramos) || $gramos <= 0) {
                throw ValidationException::withMessages(['unidad' => 'Falta el peso verificado de una unidad.']);
            }
            $cantidad *= $gramos;
            $unidad = 'gramos';
        }
        if ($unidad !== $base) {
            $densidad = $alimento['densidad_g_ml'] ?? null;
            if (! in_array($unidad, ['gramos', 'mililitros'], true) || ! is_numeric($densidad) || $densidad <= 0) {
                throw ValidationException::withMessages(['unidad' => 'Conversion incompatible o sin densidad verificada.']);
            }
            $cantidad = $base === 'gramos' ? $cantidad * $densidad : $cantidad / $densidad;
        }

        $resultado = [];
        foreach (self::NUTRIENTES as $campo) {
            $resultado[$campo] = round($cantidad / 100 * $alimento[$campo], 6);
        }

        return $resultado;
    }

    public function ajustar(array $alimentos, array $objetivos): ?array
    {
        $campos = array_keys(config('alimentacion.tolerancias'));
        $cantidades = [];
        foreach ($alimentos as $a) {
            $cantidades[] = min($a['porcion_max'], max($a['porcion_min'], $objetivos['calorias'] / count($alimentos) * 100 / $a['calorias']));
        }

        // Bounded coordinate descent minimizes relative nutrient error. It is a
        // finite heuristic, not proof that no feasible combination exists.
        for ($pasada = 0; $pasada < config('alimentacion.iteraciones_porciones'); $pasada++) {
            $cambio = 0.0;
            foreach ($alimentos as $i => $a) {
                $numerador = 0.0;
                $denominador = 0.0;
                foreach ($campos as $campo) {
                    $otros = 0.0;
                    foreach ($alimentos as $j => $otro) {
                        if ($j !== $i) {
                            $otros += $cantidades[$j] * $otro[$campo] / 100;
                        }
                    }
                    $coeficiente = $a[$campo] / 100 / $objetivos[$campo];
                    $numerador += $coeficiente * (1 - $otros / $objetivos[$campo]);
                    $denominador += $coeficiente ** 2;
                }
                $nueva = $denominador > 0 ? $numerador / $denominador : $a['porcion_min'];
                $nueva = min($a['porcion_max'], max($a['porcion_min'], $nueva));
                $cambio += abs($nueva - $cantidades[$i]);
                $cantidades[$i] = $nueva;
            }
            if ($cambio < 0.00001) {
                break;
            }
        }
        $filas = [];
        foreach ($alimentos as $i => $a) {
            $paso = (float) $a['paso_porcion'];
            $min = ceil(($a['porcion_min'] - 0.00001) / $paso);
            $max = floor(($a['porcion_max'] + 0.00001) / $paso);
            $cantidad = round(min($max, max($min, round($cantidades[$i] / $paso))) * $paso, 2);
            $filas[] = [
                'id_alimentos' => $a['id'], 'cantidad' => $cantidad, 'unidad' => $a['base_unidad'],
                'notas' => 'Cantidad de alimento en estado: '.$a['estado_preparacion'].'.',
                'detalle_nutricional' => [
                    'nombre' => $a['nombre'], 'base_cantidad' => 100, 'base_unidad' => $a['base_unidad'],
                    'estado_preparacion' => $a['estado_preparacion'], 'fuente' => $a['fuente_nutricional'],
                    'nutrientes' => $this->nutrientes($a, $cantidad, $a['base_unidad']),
                ],
            ];
        }
        $totales = $this->sumar(array_column(array_column($filas, 'detalle_nutricional'), 'nutrientes'));

        return $this->cumple($totales, $objetivos) ? ['alimentos' => $filas, 'totales' => $totales] : null;
    }

    public function sumar(array $filas): array
    {
        $total = array_fill_keys(self::NUTRIENTES, 0.0);
        foreach ($filas as $fila) {
            foreach (self::NUTRIENTES as $campo) {
                $total[$campo] += $fila[$campo];
            }
        }

        return array_map(fn ($n) => round($n, 6), $total);
    }

    public function cumple(array $totales, array $objetivos): bool
    {
        foreach (config('alimentacion.tolerancias') as $campo => $tolerancia) {
            if ($objetivos[$campo] <= 0 || abs($totales[$campo] - $objetivos[$campo]) / $objetivos[$campo] > $tolerancia) {
                return false;
            }
        }

        return true;
    }
}
