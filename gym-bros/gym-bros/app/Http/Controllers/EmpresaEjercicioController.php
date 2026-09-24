<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Requests\UpdateEmpresaEjercicioEstadoRequest;
use App\Models\Empresa;
use App\Models\Ejercicio;
use App\Models\EmpresaEjercicio;
use Illuminate\Support\Facades\DB;

class EmpresaEjercicioController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateEmpresaEjercicioEstadoRequest $request, string $id_empresa, string $id_ejercicio)
    {
        try {
            return DB::transaction(function () use ($request, $id_empresa, $id_ejercicio) {
                // Lock the company even when the pivot does not exist yet.
                $empresa = Empresa::whereKey($id_empresa)->lockForUpdate()->first();
                if (! $empresa) {
                    return response()->json(['message' => 'Empresa no encontrada.'], 404);
                }
                $ejercicio = Ejercicio::whereKey($id_ejercicio)->lockForUpdate()->first();
                if (! $ejercicio) {
                    return response()->json(['message' => 'Ejercicio no encontrado.'], 404);
                }
                $relacion = EmpresaEjercicio::firstOrNew([
                    'id_empresas' => $empresa->id, 'id_ejercicios' => $ejercicio->id,
                ]);
                $relacion->estado = (bool) $request->validated('estado');
                if (! $relacion->save()) {
                    throw new \RuntimeException('No se pudo guardar la relacion.');
                }

                return response()->json(['message' => 'Estado del ejercicio actualizado para la empresa.',
                    'id_empresa' => $empresa->id, 'id_ejercicio' => $ejercicio->id,
                    'estado' => (bool) $relacion->estado]);
            });
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo actualizar el estado del ejercicio para la empresa.'], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
