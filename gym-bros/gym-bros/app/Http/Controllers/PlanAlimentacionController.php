<?php

namespace App\Http\Controllers;

use App\Http\Resources\PlanAlimentacionResource;
use App\Models\PlanAlimentacion;
use App\Http\Requests\GenerarPlanAlimentacionRequest;
use App\Http\Resources\GeneracionPlanAlimentacionResource;
use App\Services\Alimentacion\GeneradorPlanAlimentacionService;


class PlanAlimentacionController extends Controller
{
    public function ultimoPorUsuario(string $id_usuario)
    {
        if (! \App\Models\Usuario::whereKey($id_usuario)->exists()) {
            return response()->json(['message' => 'Usuario no encontrado.'], 404);
        }
        $plan = PlanAlimentacion::where('id_usuarios', $id_usuario)->whereNotNull('calculo')
            ->with('comidas.alimentos')->orderByDesc('created_at')->orderByDesc('id')->first();
        if (! $plan) {
            return response()->json(['message' => 'El usuario no tiene un plan alimentario generado.'], 404);
        }

        return new GeneracionPlanAlimentacionResource($plan);
    }

    public function generar(GenerarPlanAlimentacionRequest $request, string $id_usuario, GeneradorPlanAlimentacionService $generador)
    {
        return (new GeneracionPlanAlimentacionResource($generador->generar((int) $id_usuario, $request->validated())))
            ->response()->setStatusCode(201);
    }

    public function detalle(string $id_usuario, string $id_plan)
    {
        $plan = PlanAlimentacion::where('id_usuarios', $id_usuario)->whereNotNull('calculo')
            ->with('comidas.alimentos')->findOrFail($id_plan);

        return new GeneracionPlanAlimentacionResource($plan);
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return PlanAlimentacionResource::collection(
            \App\Support\Acceso::limitarPorUsuario(PlanAlimentacion::query(), $this->actor())->get());
    }
}
