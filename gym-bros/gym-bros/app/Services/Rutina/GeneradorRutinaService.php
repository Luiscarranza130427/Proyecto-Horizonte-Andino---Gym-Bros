<?php

namespace App\Services\Rutina;

use App\Models\Rutina;
use App\Models\Usuario;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class GeneradorRutinaService
{
    public function __construct(
        private AnalizadorEvaluacionService $analizador,
        private DistribuidorMuscularService $distribuidor,
        private SelectorEjerciciosService $selector,
    ) {}

    public function generar(int $usuarioId): array
    {
        return DB::transaction(function () use ($usuarioId) {
            $usuario = Usuario::with('empresa')->lockForUpdate()->findOrFail($usuarioId);
            if (! $usuario->estado || ! $usuario->empresa || ! $usuario->empresa->estado) {
                throw ValidationException::withMessages(['usuario' => 'El usuario y su empresa deben estar activos.']);
            }
            $evaluacion = $usuario->evaluacionesFisicas()->orderByDesc('fecha_evaluacion')->orderByDesc('id')->first();
            if (! $evaluacion) {
                throw ValidationException::withMessages(['evaluacion' => 'El usuario no tiene una evaluacion fisica.']);
            }

            $perfil = $this->analizador->analizar($evaluacion);
            $limite = app(LimiteGeneracionService::class)->estado($usuarioId);
            if (! $limite['permitido']) {
                throw ValidationException::withMessages(['limite' => $limite['mensaje']]);
            }
            $sesiones = $this->distribuidor->distribuir($perfil);
            $candidatos = $this->selector->candidatos($usuario->id_empresas, $perfil);
            $regla = config('rutinas.objetivos.'.$perfil['objetivo']);
            $series = max(config('rutinas.series_minimas'), config('rutinas.series_por_nivel.'.$perfil['nivel']) + $regla['series_extra']);
            $frecuencias = [];
            $advertencias = ['Parametros iniciales: requieren revision del entrenador. El peso queda pendiente de asignacion.'];

            foreach ($sesiones as &$sesion) {
                $filas = [];
                foreach ($sesion['grupos'] as $grupo) {
                    $ejercicio = $this->selector->seleccionar($candidatos, $perfil, $grupo, array_column($filas, 'id_ejercicios'), $frecuencias);
                    if (! $ejercicio) {
                        throw ValidationException::withMessages(['ejercicios' => 'No hay suficientes ejercicios compatibles para '.$grupo.' en el dia '.$sesion['dia'].'.']);
                    }
                    $filas[] = ['id_ejercicios' => $ejercicio->id, 'dia' => $sesion['dia'], 'orden' => count($filas) + 1,
                        'series' => $series, 'repeticiones' => $regla['repeticiones'], 'peso' => 0,
                        'descanso_segundos' => $regla['descanso'], 'tiempo_segundos' => 0,
                        'notas' => 'Peso pendiente de asignacion por el entrenador. Dia semanal: '.config('rutinas.dias')[$sesion['dia_semana'] - 1].'.'];
                }
                if ($regla['cardio_segundos'] > 0) {
                    $cardio = $this->selector->seleccionar($candidatos, $perfil, null, array_column($filas, 'id_ejercicios'), $frecuencias);
                    if ($cardio) {
                        $filas[] = ['id_ejercicios' => $cardio->id, 'dia' => $sesion['dia'], 'orden' => count($filas) + 1,
                            'series' => 1, 'repeticiones' => 0, 'peso' => 0, 'descanso_segundos' => 0,
                            'tiempo_segundos' => $regla['cardio_segundos'], 'notas' => 'Bloque por tiempo; intensidad a revisar con el entrenador.'];
                    } else {
                        $advertencias[] = 'No hay cardio compatible disponible; se genero el bloque de fuerza.';
                    }
                }
                $filas = $this->ajustarTiempo($filas, $perfil['tiempo_sesion_min'] * 60, $advertencias);
                foreach ($filas as &$fila) {
                    if ($fila['repeticiones'] > 0) {
                        $fila['tiempo_segundos'] = $this->duracionEjercicio($fila);
                    }
                    $frecuencias[$fila['id_ejercicios']] = ($frecuencias[$fila['id_ejercicios']] ?? 0) + 1;
                }
                unset($fila);
                $sesion['ejercicios'] = $filas;
                $sesion['duracion_estimada_segundos'] = $this->duracionSesion($filas);
            }
            unset($sesion);

            $inicio = today()->startOfWeek()->addDays($perfil['calendario'][0] - 1);
            if ($inicio->lt(today())) {
                $inicio->addWeek();
            }
            $rutina = Rutina::create(['id_usuarios' => $usuario->id, 'nombre' => 'Rutina '.$perfil['objetivo'],
                'descripcion' => 'Generada por reglas v1. Evaluacion '.$evaluacion->id.'. Actividad: '.$perfil['actividad_diaria'].'.',
                'objetivo' => $perfil['objetivo'], 'dias_semana' => $perfil['dias_semana'],
                'duracion_estimada' => (int) ceil(max(array_column($sesiones, 'duracion_estimada_segundos')) / 60),
                'fecha_inicio' => $inicio->toDateString(), 'fecha_fin' => $inicio->copy()->addWeeks(config('rutinas.vigencia_semanas'))->subDay()->toDateString(),
                'estado' => true]);
            foreach ($sesiones as $sesion) {
                $rutina->ejerciciosRutina()->createMany($sesion['ejercicios']);
            }
            $rutina->load('ejerciciosRutina.ejercicio.grupomuscular');
            DB::table('routine_generation_usage')->insert([
                'user_id' => $usuarioId, 'routine_id' => $rutina->id,
                'evaluation_hash' => $limite['evaluation_hash'], 'created_at' => now(),
            ]);

            return ['rutina' => $rutina, 'sesiones' => $sesiones, 'advertencias' => array_values(array_unique($advertencias))];
        });
    }

    private function ajustarTiempo(array $filas, int $limite, array &$advertencias): array
    {
        while ($this->duracionSesion($filas) > $limite) {
            $cambio = false;
            for ($i = count($filas) - 1; $i >= 0; $i--) {
                if ($filas[$i]['repeticiones'] > 0 && $filas[$i]['series'] > config('rutinas.series_minimas')) {
                    $filas[$i]['series']--;
                    $cambio = true;
                    break;
                }
            }
            if ($cambio) {
                continue;
            }
            if (end($filas)['repeticiones'] === 0) {
                array_pop($filas);
                $advertencias[] = 'Se omitio el cardio adicional para respetar el tiempo disponible.';
                continue;
            }
            throw ValidationException::withMessages(['tiempo_sesion_min' => 'El tiempo no alcanza para cubrir los grupos y descansos minimos de esta distribucion.']);
        }
        return $filas;
    }

    private function duracionEjercicio(array $fila): int
    {
        return $fila['repeticiones'] === 0 ? $fila['tiempo_segundos']
            : $fila['series'] * $fila['repeticiones'] * config('rutinas.segundos_repeticion')
                + ($fila['series'] - 1) * $fila['descanso_segundos'];
    }

    private function duracionSesion(array $filas): int
    {
        return config('rutinas.calentamiento_segundos') + array_sum(array_map($this->duracionEjercicio(...), $filas))
            + max(0, count($filas) - 1) * config('rutinas.transicion_segundos');
    }
}
