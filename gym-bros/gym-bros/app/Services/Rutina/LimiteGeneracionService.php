<?php

namespace App\Services\Rutina;

use App\Models\Usuario;
use Illuminate\Support\Facades\DB;

class LimiteGeneracionService
{
    public function estado(int $userId): array
    {
        $user = Usuario::findOrFail($userId);
        $evaluation = $user->evaluacionesFisicas()->orderByDesc('fecha_evaluacion')->orderByDesc('id')->first();
        $values = $evaluation ? $evaluation->only($evaluation->getFillable()) : [];
        unset($values['fecha_evaluacion'], $values['id_usuarios']);
        ksort($values);
        $hash = hash('sha256', json_encode($values));
        $now = now('America/Lima');
        $usage = DB::table('routine_generation_usage')->where('user_id', $userId)
            ->where('created_at', '>=', $now->copy()->startOfMonth()->setTimezone(config('app.timezone')))
            ->where('created_at', '<', $now->copy()->startOfMonth()->addMonth()->setTimezone(config('app.timezone')));
        $legacyCount = DB::table('rutinas')->where('id_usuarios', $userId)
            ->where('descripcion', 'like', 'Generada por reglas v1.%')
            ->whereNotIn('id', DB::table('routine_generation_usage')->select('routine_id'))
            ->where('created_at', '>=', $now->copy()->startOfMonth()->setTimezone(config('app.timezone')))
            ->where('created_at', '<', $now->copy()->startOfMonth()->addMonth()->setTimezone(config('app.timezone')))->count();
        $count = (clone $usage)->count() + $legacyCount;
        $alreadyUsed = (clone $usage)->where('evaluation_hash', $hash)->exists();
        // Older routines have no evaluation snapshot. Only accept an exception
        // when the evaluation was updated after the last historical generation.
        $legacyUnchanged = false;
        if ($legacyCount > 0 && (clone $usage)->count() === 0) {
            $latest = DB::table('rutinas')->where('id_usuarios', $userId)
                ->where('descripcion', 'like', 'Generada por reglas v1.%')->max('created_at');
            $legacyUnchanged = ! $evaluation?->updated_at || ! $evaluation->updated_at->gt($latest);
        }
        $blocked = $count >= 3 && ($alreadyUsed || $legacyUnchanged);
        return [
            'permitido' => $evaluation !== null && ! $blocked,
            'generadas_mes' => $count,
            'limite_mensual' => 3,
            'evaluation_hash' => $hash,
            'mensaje' => ! $evaluation ? 'Registra tu evaluación física para generar una rutina.' :
                ($blocked ? 'Alcanzaste las 3 generaciones del mes. Podrás generar otra al modificar tu evaluación física o comenzar un nuevo mes.' :
                ($count >= 3 ? 'Tu evaluación cambió: puedes generar una nueva rutina.' : 'Puedes generar hasta 3 rutinas al mes.')),
        ];
    }
}
