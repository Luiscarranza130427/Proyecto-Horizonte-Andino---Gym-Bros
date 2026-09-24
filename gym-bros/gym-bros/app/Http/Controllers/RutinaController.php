<?php

namespace App\Http\Controllers;

use App\Http\Resources\RutinaResource;
use App\Models\Rutina;
use App\Http\Resources\GeneracionRutinaResource;
use App\Http\Resources\EjercicioRutinaResource;
use App\Services\Rutina\GeneradorRutinaService;
use Illuminate\Http\Request;


class RutinaController extends Controller
{
    public function sesion(Request $request, string $id_usuario, string $id_rutina, string $dia)
    {
        $rutina = Rutina::where('id_usuarios', $id_usuario)->findOrFail($id_rutina);

        if ($dia < 1 || $dia > $rutina->dias_semana) {
            return response()->json(['message' => 'La sesion no pertenece a esta rutina.'], 404);
        }

        $ejercicios = $rutina->ejerciciosRutina()->where('dia', $dia)
            ->with('ejercicio.grupomuscular')->orderBy('id')->get();

        if ($ejercicios->isEmpty()) {
            return response()->json(['message' => 'No hay ejercicios guardados para esta sesion.'], 404);
        }

        return response()->json(['data' => [
            'id_usuarios' => $rutina->id_usuarios,
            'id_rutinas' => $rutina->id,
            'dia' => (int) $dia,
            'dias_semana' => $rutina->dias_semana,
            'duracion_estimada' => $rutina->duracion_estimada,
            'objetivo' => $rutina->objetivo,
            'ejercicios' => EjercicioRutinaResource::collection($ejercicios)->resolve($request),
        ]]);
    }

    public function generar(string $id_usuario, GeneradorRutinaService $generador)
    {
        return (new GeneracionRutinaResource($generador->generar((int) $id_usuario)))
            ->response()->setStatusCode(201);
    }

    public function estadoGeneracion(string $id_usuario, \App\Services\Rutina\LimiteGeneracionService $limite)
    {
        $estado = $limite->estado((int) $id_usuario);
        unset($estado['evaluation_hash']);

        return response()->json(['data' => $estado]);
    }

    public function index()
    {
        return RutinaResource::collection(\App\Support\Acceso::limitarPorUsuario(Rutina::query(), $this->actor())->get());
    }
}
