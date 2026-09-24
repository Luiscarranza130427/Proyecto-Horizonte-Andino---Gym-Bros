<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class AlimentacionDisponible
{
    public function handle($request, Closure $next)
    {
        $request->headers->set('Accept', 'application/json');
        if (! Schema::hasTable('perfiles_alimentarios')
            || ! Schema::hasColumn('comida_alimentos', 'detalle_nutricional')
            || ! Schema::hasColumn('evaluaciones_fisicas', 'altura_unidad')) {
            return response()->json(['message' => 'Alimentacion pendiente de migraciones aprobadas.'], 503);
        }

        try {
            return $next($request);
        } catch (ValidationException $exception) {
            return response()->json(['message' => $exception->getMessage(), 'errors' => $exception->errors()], 422);
        } catch (ModelNotFoundException $exception) {
            return response()->json(['message' => 'El recurso solicitado no existe o no pertenece al usuario.'], 404);
        }
    }
}
