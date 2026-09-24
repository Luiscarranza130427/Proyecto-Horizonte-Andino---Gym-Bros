<?php

namespace App\Http\Controllers;

use App\Http\Resources\EvaluacionFisicaResource;
use App\Models\EvaluacionFisica;
use App\Models\Usuario;
use App\Http\Requests\StoreEvaluacionFisicaRequest;
use App\Http\Requests\UpdateEvaluacionFisicaRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class EvaluacionFisicaController extends Controller
{
    public function perfil(string $id_usuario)
    {
        $usuario = Usuario::findOrFail($id_usuario);
        $evaluacion = $usuario->evaluacionesFisicas()
            ->orderByDesc('fecha_evaluacion')->orderByDesc('id')
            ->first(['id', 'id_usuarios', 'fecha_evaluacion', 'objetivo', 'nivel_experiencia',
                'actividad_diaria', 'dias_semana', 'eleccion_dias', 'tiempo_sesion_min', 'restricciones']);

        if (! $evaluacion) {
            return response()->json(['message' => 'El usuario no tiene evaluaciones fisicas registradas.'], 404);
        }

        return response()->json(['data' => [
            'id_usuarios' => $evaluacion->id_usuarios,
            'id_evaluacion' => $evaluacion->id,
            'fecha_evaluacion' => $evaluacion->fecha_evaluacion,
            'objetivo' => $evaluacion->objetivo,
            'nivel_experiencia' => $evaluacion->nivel_experiencia,
            'actividad_diaria' => $evaluacion->actividad_diaria,
            'dias_semana' => (int) $evaluacion->dias_semana,
            'eleccion_dias' => $evaluacion->eleccion_dias,
            'tiempo_sesion_min' => (int) $evaluacion->tiempo_sesion_min,
            'restricciones' => $evaluacion->restricciones,
        ]]);
    }

    public function pesoGrasa(string $id_usuario)
    {
        $usuario = Usuario::findOrFail($id_usuario);
        $evaluacion = $usuario->evaluacionesFisicas()
            ->orderByDesc('fecha_evaluacion')->orderByDesc('id')
            ->first(['id', 'id_usuarios', 'fecha_evaluacion', 'peso', 'porcentaje_grasa']);

        if (! $evaluacion) {
            return response()->json(['message' => 'El usuario no tiene evaluaciones fisicas registradas.'], 404);
        }

        return response()->json(['data' => [
            'id_usuarios' => $evaluacion->id_usuarios,
            'id_evaluacion' => $evaluacion->id,
            'fecha_evaluacion' => $evaluacion->fecha_evaluacion,
            'peso' => (float) $evaluacion->peso,
            'porcentaje_grasa' => (float) $evaluacion->porcentaje_grasa,
        ]]);
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return EvaluacionFisicaResource::collection(
            \App\Support\Acceso::limitarPorUsuario(EvaluacionFisica::query(), $this->actor())->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreEvaluacionFisicaRequest $request, string $id_usuario)
    {
        $usuario = Usuario::findOrFail($id_usuario);
        $datos = $request->validated();
        if (\Illuminate\Support\Facades\Schema::hasColumn('evaluaciones_fisicas', 'altura_unidad')) {
            $datos['altura_unidad'] = 'cm';
        }
        $evaluacion = $usuario->evaluacionesFisicas()->create($datos);
        $evaluacion->refresh();

        return response()->json(['data' => [
            'id_usuarios' => $evaluacion->id_usuarios,
        ] + (new EvaluacionFisicaResource($evaluacion))->resolve($request)], 201);
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
    public function update(UpdateEvaluacionFisicaRequest $request, string $id_usuario)
    {
        return DB::transaction(function () use ($request, $id_usuario) {
            $usuario = Usuario::lockForUpdate()->findOrFail($id_usuario);
            $evaluacion = $usuario->evaluacionesFisicas()
                ->orderByDesc('fecha_evaluacion')->orderByDesc('id')->lockForUpdate()->first();

            if (! $evaluacion) {
                return response()->json(['message' => 'El usuario no tiene evaluaciones fisicas registradas.'], 404);
            }

            $datos = $request->validated();
            if ($datos === []) {
                return response()->json([
                    'message' => 'Debe enviar al menos un campo de la evaluacion para actualizar.',
                    'errors' => ['evaluacion' => ['Debe enviar al menos un campo de la evaluacion para actualizar.']],
                ], 422);
            }

            if (array_key_exists('dias_semana', $datos) || array_key_exists('eleccion_dias', $datos)) {
                $diasSemana = $datos['dias_semana'] ?? $evaluacion->dias_semana;
                $diasElegidos = array_key_exists('eleccion_dias', $datos) ? $datos['eleccion_dias'] : $evaluacion->eleccion_dias;
                $validator = Validator::make(['eleccion_dias' => $diasElegidos], [
                    'eleccion_dias' => ['nullable', 'array', 'size:'.$diasSemana],
                ], ['eleccion_dias.size' => 'La cantidad de dias elegidos debe coincidir con dias_semana.']);

                if ($validator->fails()) {
                    return response()->json([
                        'message' => 'Los datos de la evaluacion fisica no son validos.',
                        'errors' => $validator->errors(),
                    ], 422);
                }
            }

            if (array_key_exists('altura', $datos)
                && \Illuminate\Support\Facades\Schema::hasColumn('evaluaciones_fisicas', 'altura_unidad')) {
                $datos['altura_unidad'] = 'cm';
            }
            $evaluacion->update($datos);
            $evaluacion->refresh();

            return response()->json(['data' => [
                'id_usuarios' => $evaluacion->id_usuarios,
            ] + (new EvaluacionFisicaResource($evaluacion))->resolve($request)]);
        });
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
