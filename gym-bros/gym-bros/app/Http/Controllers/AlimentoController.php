<?php

namespace App\Http\Controllers;

use App\Http\Resources\AlimentoResource;
use App\Models\Alimento;
use Illuminate\Http\Request;
use App\Http\Requests\UpdateAlimentoRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use App\Services\Alimentacion\CalculadorPorcionesService;


class AlimentoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $datos = $request->validate([
            'search' => ['nullable', 'string', 'max:150'],
            'type' => ['nullable', 'string', 'max:50'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
        $query = Alimento::where('activo', true)->orderBy('id');
        if (! empty($datos['search'])) {
            $query->where('nombre', 'like', '%'.$datos['search'].'%');
        }
        if (! empty($datos['type'])) {
            $query->where('tipo', $datos['type']);
        }

        return AlimentoResource::collection(isset($datos['page']) || isset($datos['per_page'])
            ? $query->paginate($datos['per_page'] ?? 12)->withQueryString() : $query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(\App\Http\Requests\StoreAlimentoRequest $request)
    {
        // Antes llamaba a validate() sin reglas: cualquier alta devolvia 500.
        $alimento = new Alimento($request->validated() + ['activo' => true]);
        if ($alimento->base_unidad !== null
            && ! app(CalculadorPorcionesService::class)->datosValidos($alimento->toArray())) {
            return response()->json(['message' => 'Los datos del alimento no son validos.',
                'errors' => ['alimento' => ['Revise nutrientes, base y limites de porcion: son incoherentes.']]], 422);
        }
        $alimento->save();

        return (new AlimentoResource($alimento->refresh()))->response()->setStatusCode(201);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateAlimentoRequest $request, string $id_alimento)
    {
        try {
            $alimento = DB::transaction(function () use ($request, $id_alimento) {
                $alimento = Alimento::whereKey($id_alimento)->lockForUpdate()->first();
                if (! $alimento) {
                    return null;
                }
                $datos = $request->validated();
                $alimento->fill($datos);
                $camposNutricionales = array_diff(array_keys($request->rules()), ['nombre', 'tipo', 'activo']);
                if ($alimento->base_unidad !== null && array_intersect(array_keys($datos), $camposNutricionales) !== []
                    && ! app(CalculadorPorcionesService::class)->datosValidos($alimento->toArray())) {
                    throw ValidationException::withMessages([
                        'alimento' => 'Revise nutrientes, base y limites de porcion: son incoherentes.',
                    ]);
                }
                if (! $alimento->save()) {
                    throw new \RuntimeException('No se pudo guardar el alimento.');
                }

                return $alimento->refresh();
            });
        } catch (ValidationException $exception) {
            return response()->json(['message' => 'Los datos del alimento no son validos.', 'errors' => $exception->errors()], 422);
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo actualizar el alimento.'], 500);
        }
        if (! $alimento) {
            return response()->json(['message' => 'Alimento no encontrado.'], 404);
        }

        return new AlimentoResource($alimento);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id_alimento)
    {
        try {
            return DB::transaction(function () use ($id_alimento) {
                $alimento = Alimento::whereKey($id_alimento)->lockForUpdate()->first();
                if (! $alimento) {
                    return response()->json(['message' => 'Alimento no encontrado.'], 404);
                }
                // Prevent cascading deletion of existing plans and user preferences.
                foreach (['comida_alimentos', 'preferencias_alimentarias'] as $tabla) {
                    if (DB::table($tabla)->where('id_alimentos', $id_alimento)->lockForUpdate()->first()) {
                        return response()->json([
                            'message' => 'El alimento esta relacionado con comidas o preferencias de usuarios. Desactivelo en lugar de eliminarlo.',
                        ], 409);
                    }
                }
                if (! $alimento->delete()) {
                    throw new \RuntimeException('No se pudo eliminar el alimento.');
                }

                return response()->json(['message' => 'Alimento eliminado correctamente.']);
            });
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo eliminar el alimento.'], 500);
        }
    }
}
