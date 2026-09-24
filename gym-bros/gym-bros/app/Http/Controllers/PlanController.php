<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePlanRequest;
use App\Http\Requests\UpdatePlanRequest;
use App\Http\Resources\PlanResource;
use App\Models\Plan;
use App\Models\Suscripcion;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    /** Catalogo comercial publico. `estado` (activo|inactivo) y `search` son opcionales. */
    public function index(Request $request)
    {
        $filtros = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'estado' => ['nullable', 'in:activo,inactivo,1,0,true,false'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
        $planes = Plan::query()->orderBy('id');
        if (($filtros['search'] ?? null) !== null && trim($filtros['search']) !== '') {
            $planes->where('nombre', 'like', '%'.addcslashes(trim($filtros['search']), '%_\\').'%');
        }
        if (($filtros['estado'] ?? null) !== null) {
            $planes->where('activo', in_array($filtros['estado'], ['activo', '1', 'true'], true));
        }
        if (isset($filtros['page']) || isset($filtros['per_page'])) {
            return PlanResource::collection($planes->paginate((int) ($filtros['per_page'] ?? 15))->withQueryString());
        }

        return PlanResource::collection($planes->get());
    }

    public function show(string $id_plan)
    {
        $plan = Plan::find($id_plan);

        return $plan ? new PlanResource($plan) : response()->json(['message' => 'Plan no encontrado.'], 404);
    }

    public function store(StorePlanRequest $request)
    {
        $plan = new Plan();
        $plan->forceFill($request->validated())->save();

        return (new PlanResource($plan->refresh()))->response()->setStatusCode(201);
    }

    public function update(UpdatePlanRequest $request, string $id_plan)
    {
        $plan = Plan::find($id_plan);
        if (! $plan) {
            return response()->json(['message' => 'Plan no encontrado.'], 404);
        }
        $plan->forceFill($request->validated())->save();

        return new PlanResource($plan->refresh());
    }

    /** Un plan con suscripciones o compras conserva el historial: se desactiva en su lugar. */
    public function destroy(string $id_plan)
    {
        $plan = Plan::find($id_plan);
        if (! $plan) {
            return response()->json(['message' => 'Plan no encontrado.'], 404);
        }
        $enUso = Suscripcion::where('id_planes', $plan->id)->exists()
            || (\Illuminate\Support\Facades\Schema::hasTable('ordenes_compra')
                && \Illuminate\Support\Facades\DB::table('ordenes_compra')->where('id_planes', $plan->id)->exists());
        if ($enUso) {
            return response()->json(['message' => 'El plan tiene suscripciones o compras asociadas. Desactivalo en lugar de eliminarlo.'], 409);
        }
        $plan->delete();

        return response()->json(['message' => 'Plan eliminado.', 'data' => ['id' => (int) $id_plan]]);
    }
}
