<?php

namespace App\Http\Controllers;

use App\Http\Resources\PagoResource;
use App\Models\Pago;
use App\Support\Acceso;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class PagoController extends Controller
{
    public function index(Request $request)
    {
        $filtros = $this->filtros($request);
        $pagos = $this->consulta($filtros)->with(['empresa', 'suscripcion.plan'])->orderByDesc('id');
        if (isset($filtros['page']) || isset($filtros['per_page'])) {
            return PagoResource::collection($pagos->paginate((int) ($filtros['per_page'] ?? 15))->withQueryString());
        }

        return PagoResource::collection($pagos->get());
    }

    /** Totales del mismo alcance y filtros que el listado; solo cuentan pagos aprobados. */
    public function metricas(Request $request)
    {
        // Columnas calificadas: el calculo de meses une `suscripciones`, que tambien tiene `estado`.
        $aprobados = $this->consulta($this->filtros($request))->where('pagos.estado', 'aprobado');
        $total = (float) (clone $aprobados)->sum('pagos.monto');
        $cantidad = (clone $aprobados)->count();
        $meses = (clone $aprobados)->join('suscripciones', 'suscripciones.id', '=', 'pagos.id_suscripciones')
            ->get(['suscripciones.fecha_inicio', 'suscripciones.fecha_fin'])
            ->sum(fn ($s) => max(1, (int) round((strtotime((string) $s->fecha_fin) - strtotime((string) $s->fecha_inicio)) / 2_592_000)));

        return response()->json(['data' => [
            'totalIngresos' => round($total, 2),
            'totalTransacciones' => $cantidad,
            'ticketPromedio' => $cantidad ? round($total / $cantidad, 2) : 0,
            'totalMeses' => $meses,
            'moneda' => (clone $aprobados)->value('pagos.moneda') ?? 'PEN',
        ]]);
    }

    public function show(string $id_pago)
    {
        $pago = Pago::with(['empresa', 'suscripcion.plan'])->find($id_pago);
        if (! $pago) {
            return response()->json(['message' => 'Pago no encontrado.'], 404);
        }
        if (! Acceso::puedeVerEmpresa($this->actor(), $pago->id_empresas)) {
            return response()->json(['message' => 'No tiene autorizacion para realizar esta accion.'], 403);
        }

        return new PagoResource($pago);
    }

    private function filtros(Request $request): array
    {
        return $request->validate([
            'search' => ['nullable', 'string', 'max:150'],
            'empresa_id' => ['nullable', 'integer', 'min:1'],
            'plan_id' => ['nullable', 'integer', 'min:1'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
    }

    private function consulta(array $filtros): Builder
    {
        $pagos = Acceso::limitarPorEmpresa(Pago::query(), $this->actor(), 'pagos.id_empresas');
        if (! empty($filtros['empresa_id'])) {
            $pagos->where('pagos.id_empresas', $filtros['empresa_id']);
        }
        if (! empty($filtros['plan_id'])) {
            $pagos->whereHas('suscripcion', fn ($q) => $q->where('id_planes', $filtros['plan_id']));
        }
        if (($filtros['search'] ?? null) !== null && trim($filtros['search']) !== '') {
            $patron = '%'.addcslashes(trim($filtros['search']), '%_\\').'%';
            $pagos->where(fn ($q) => $q->where('pagos.referencia', 'like', $patron)
                ->orWhereHas('empresa', fn ($e) => $e->where('nombre', 'like', $patron)));
        }

        return $pagos;
    }
}
