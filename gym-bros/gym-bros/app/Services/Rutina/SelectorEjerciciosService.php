<?php

namespace App\Services\Rutina;

use App\Models\Ejercicio;
use Illuminate\Support\Collection;

class SelectorEjerciciosService
{
    public function candidatos(int $empresaId, array $perfil): Collection
    {
        $rango = config('rutinas.niveles.'.$perfil['nivel']);
        $niveles = array_keys(array_filter(config('rutinas.niveles'), fn ($nivel) => $nivel <= $rango));

        return Ejercicio::query()->where('estado', true)->whereIn('nivel', $niveles)
            ->whereHas('empresas', fn ($query) => $query->where('empresas.id', $empresaId)->where('empresa_ejercicio.estado', true))
            ->whereHas('grupomuscular', fn ($query) => $query->where('estado', true))
            ->with(['grupomuscular', 'gruposMusculares' => fn ($query) => $query->where('grupos_musculares.estado', true)])
            ->orderBy('id')->get();
    }

    public function seleccionar(Collection $candidatos, array $perfil, ?string $grupo, array $usados, array $frecuencias): ?Ejercicio
    {
        $tipo = $grupo === null ? 'cardio' : 'fuerza';
        return $candidatos->filter(function (Ejercicio $ejercicio) use ($grupo, $tipo, $usados) {
            return $ejercicio->tipo === $tipo && ! in_array($ejercicio->id, $usados, true)
                && ($grupo === null || in_array($grupo, $this->grupos($ejercicio), true));
        })->sort(function (Ejercicio $a, Ejercicio $b) use ($perfil, $grupo, $frecuencias) {
            return $this->puntuar($b, $perfil, $grupo, $frecuencias) <=> $this->puntuar($a, $perfil, $grupo, $frecuencias)
                ?: $a->id <=> $b->id;
        })->first();
    }

    public function puntuar(Ejercicio $ejercicio, array $perfil, ?string $grupo, array $frecuencias = []): int
    {
        $puntos = config('rutinas.puntuacion');
        $total = $ejercicio->nivel === $perfil['nivel'] ? $puntos['nivel_exacto'] : $puntos['nivel_inferior'];
        if ($grupo !== null && in_array($grupo, $this->grupos($ejercicio), true)) {
            $total += $puntos['grupo'];
            if ($this->normalizar($ejercicio->grupomuscular->tipo) === $grupo) {
                $total += $puntos['principal'];
            }
        }
        if ($ejercicio->tipo === 'fuerza' || ($ejercicio->tipo === 'cardio' && config('rutinas.objetivos.'.$perfil['objetivo'].'.cardio_segundos') > 0)) {
            $total += $puntos['objetivo'];
        }
        return $total - ($frecuencias[$ejercicio->id] ?? 0) * $puntos['repetido_semana'];
    }

    private function grupos(Ejercicio $ejercicio): array
    {
        return $ejercicio->gruposMusculares->pluck('tipo')->push($ejercicio->grupomuscular->tipo)
            ->map(fn ($tipo) => $this->normalizar($tipo))->unique()->values()->all();
    }

    private function normalizar(string $tipo): string
    {
        return config('rutinas.alias_musculares.'.$tipo, $tipo);
    }
}
