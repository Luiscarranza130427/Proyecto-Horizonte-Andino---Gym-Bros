<?php

namespace App\Http\Middleware;

use App\Models\Usuario;
use Closure;
use Illuminate\Support\Facades\Gate;

class AutorizarUsuarioAlimentacion
{
    public function handle($request, Closure $next)
    {
        $id = $request->route('id_usuario');
        if ($id === null) {
            return $next($request);
        }
        $actor = $request->user();
        if (! $actor) {
            // Vue's development placeholder is not a real identity or production token.
            $lecturaSimulada = app()->environment('local')
                && $request->isMethod('GET') && $request->routeIs('usuarios.plan-alimentacion')
                && preg_match('/\Adesarrollo-sin-backend-[0-9]+\z/', (string) $request->bearerToken()) === 1;
            if (app()->environment(['local', 'testing']) && config('alimentacion.permitir_sin_sesion_local')
                && (! $request->headers->has('Authorization') || $lecturaSimulada)) {
                return $next($request);
            }

            return response()->json(['message' => 'Se requiere autenticacion.',
                'errors' => ['autenticacion' => ['No existe una identidad autenticada.']]], 401);
        }
        // The default User model belongs to another table; matching numeric IDs
        // alone cannot establish ownership of a domain Usuario.
        if ($actor instanceof Usuario && (string) $actor->getKey() === (string) $id) {
            return $next($request);
        }
        $usuario = Usuario::findOrFail($id);
        if (Gate::forUser($actor)->allows('gestionar-alimentacion', $usuario)) {
            return $next($request);
        }

        return response()->json(['message' => 'No tiene autorizacion para este usuario.',
            'errors' => ['autorizacion' => ['El perfil pertenece a otro usuario.']]], 403);
    }
}
