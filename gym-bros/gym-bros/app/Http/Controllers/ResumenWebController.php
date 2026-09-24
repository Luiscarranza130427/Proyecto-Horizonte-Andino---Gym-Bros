<?php

namespace App\Http\Controllers;

use App\Http\Resources\PlanResource;
use App\Models\Ejercicio;
use App\Models\Empresa;
use App\Models\Suscripcion;
use App\Models\Usuario;
use Illuminate\Http\Request;

class ResumenWebController extends Controller
{
    public function index(Request $request, string $id_usuario)
    {
        $usuario = Usuario::with('empresa')->find($id_usuario);
        if (! $usuario) {
            return response()->json(['message' => 'Usuario no encontrado.'], 404);
        }

        // Read the role and company from storage, never from client parameters.
        $tipo = strtolower(trim($usuario->tipo_usuario));
        if (! $usuario->estado || ! in_array($tipo, ['administrador', 'empresa', 'entrenador'], true)) {
            return response()->json(['message' => 'El usuario no tiene acceso al resumen web.'], 403);
        }
        $administrador = $tipo === 'administrador';
        if (! $administrador && ! $usuario->empresa) {
            return response()->json(['message' => 'El usuario no tiene una empresa asociada.',
                'errors' => ['id_empresas' => ['Se requiere una empresa existente.']]], 422);
        }

        $usuarios = Usuario::query();
        $ejercicios = Ejercicio::query();
        if (! $administrador) {
            $usuarios->where('id_empresas', $usuario->id_empresas);
            $ejercicios->where('estado', true)->whereHas('empresas', fn ($query) => $query
                ->where('empresas.id', $usuario->id_empresas)->where('empresa_ejercicio.estado', true));
        }

        $suscripcion = $usuario->empresa ? Suscripcion::with('plan')
            ->where('id_empresas', $usuario->id_empresas)->where('estado', 'activa')
            ->where('fecha_inicio', '<=', today()->toDateString())->where('fecha_fin', '>=', today()->toDateString())
            ->orderByDesc('fecha_inicio')->orderByDesc('id')->first() : null;
        $plan = null;
        if ($suscripcion?->plan) {
            $plan = (new PlanResource($suscripcion->plan))->resolve($request) + [
                'duracion_dias' => (int) $suscripcion->plan->duracion_dias,
                'id_suscripcion' => $suscripcion->id,
                'fecha_inicio' => $suscripcion->fecha_inicio,
                'fecha_fin' => $suscripcion->fecha_fin,
                'estado_suscripcion' => $suscripcion->estado,
            ];
        }

        $data = ['id_usuario' => $usuario->id, 'tipo_usuario' => $usuario->tipo_usuario,
            'id_empresa' => $usuario->empresa?->id, 'alcance' => $administrador ? 'global' : 'empresa',
            'cantidad_usuarios' => $usuarios->count(), 'cantidad_ejercicios' => $ejercicios->count(),
            'plan_empresa' => $plan];
        if ($administrador) {
            $data['cantidad_empresas'] = Empresa::count();
        }

        return response()->json(['data' => $data]);
    }
}
