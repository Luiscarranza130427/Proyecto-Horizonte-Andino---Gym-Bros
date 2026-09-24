<?php

namespace App\Services\Alimentacion;

use App\Models\Alimento;
use App\Models\PreferenciaAlimentaria;
use Illuminate\Validation\ValidationException;

class SelectorAlimentosService
{
    public function __construct(private CalculadorPorcionesService $porciones) {}

    public function candidatos(int $usuarioId): array
    {
        $preferencias = PreferenciaAlimentaria::where('id_usuarios', $usuarioId)->where('activo', true)->get();
        if ($preferencias->contains(fn ($p) => ! in_array($p->tipo, ['preferido', 'rechazado'], true))) {
            throw ValidationException::withMessages(['preferencias' => 'Confirme el tipo de las preferencias historicas.']);
        }
        $rechazados = $preferencias->where('tipo', 'rechazado')->pluck('id_alimentos')->all();
        $preferidos = $preferencias->where('tipo', 'preferido')->pluck('id_alimentos')->all();
        return Alimento::where('activo', true)->where('nutricion_verificada', true)
            ->whereNotIn('id', $rechazados)->orderBy('id')->get()
            ->map(function ($a) use ($preferidos) {
                $datos = $a->toArray();
                $datos['preferido'] = in_array($a->id, $preferidos);
                return $datos;
            })->filter(fn ($a) => $this->porciones->datosValidos($a))->values()->all();
    }

    public function seleccionar(array $candidatos, string $tipo, array $objetivos, array &$usos): array
    {
        $grupos = [];
        foreach (config('alimentacion.grupos_comida.'.$tipo) as $grupo) {
            $lista = array_values(array_filter($candidatos, fn ($a) => ($a['grupo_menu'] ?? null) === $grupo
                && is_array($a['tipos_comida'] ?? null) && in_array($tipo, $a['tipos_comida'], true)));
            usort($lista, fn ($a, $b) => [$usos[$a['id']] ?? 0, ! $a['preferido'], $a['id']]
                <=> [$usos[$b['id']] ?? 0, ! $b['preferido'], $b['id']]);
            if ($lista === []) {
                throw ValidationException::withMessages(['alimentos' => 'Faltan alimentos verificados compatibles: '.$grupo.' para '.$tipo.'.']);
            }
            $grupos[] = array_slice($lista, 0, config('alimentacion.max_candidatos_grupo'));
        }
        $resultado = $this->buscar($grupos, [], $objetivos);
        if (! $resultado) {
            throw ValidationException::withMessages(['porciones' => 'No se encontro una combinacion dentro de los limites y tolerancias para '.$tipo.'. Revise el catalogo.']);
        }
        foreach ($resultado['alimentos'] as $alimento) {
            $usos[$alimento['id_alimentos']] = ($usos[$alimento['id_alimentos']] ?? 0) + 1;
        }

        return $resultado;
    }

    private function buscar(array $grupos, array $seleccion, array $objetivos): ?array
    {
        if ($grupos === []) {
            return $this->porciones->ajustar($seleccion, $objetivos);
        }
        $grupo = array_shift($grupos);
        foreach ($grupo as $alimento) {
            $resultado = $this->buscar($grupos, [...$seleccion, $alimento], $objetivos);
            if ($resultado) {
                return $resultado;
            }
        }

        return null;
    }
}
