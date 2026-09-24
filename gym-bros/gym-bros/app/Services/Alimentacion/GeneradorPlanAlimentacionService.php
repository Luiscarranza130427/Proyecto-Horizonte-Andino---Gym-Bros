<?php

namespace App\Services\Alimentacion;

use App\Models\PerfilAlimentario;
use App\Models\PlanAlimentacion;
use App\Models\Usuario;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class GeneradorPlanAlimentacionService
{
    public function __construct(
        private CalculadorObjetivosService $calculador,
        private SelectorAlimentosService $selector,
        private CalculadorPorcionesService $porciones,
    ) {}

    public function generar(int $usuarioId, array $datos): PlanAlimentacion
    {
        if (! config('alimentacion.habilitado')) {
            throw new HttpException(503, 'La generacion de planes esta deshabilitada por configuracion.');
        }

        return DB::transaction(function () use ($usuarioId, $datos) {
            $usuario = Usuario::with('empresa')->lockForUpdate()->findOrFail($usuarioId);
            if (! $usuario->estado || ! $usuario->empresa || ! $usuario->empresa->estado) {
                throw ValidationException::withMessages(['usuario' => 'El usuario y su empresa deben estar activos.']);
            }
            $evaluacion = $usuario->evaluacionesFisicas()->orderByDesc('fecha_evaluacion')->orderByDesc('id')->lockForUpdate()->first();
            $perfil = PerfilAlimentario::where('id_usuarios', $usuarioId)->first();
            if (! $evaluacion || ! $perfil) {
                throw ValidationException::withMessages(['evaluacion' => 'Se requiere evaluacion fisica y perfil alimentario.']);
            }
            $inicio = CarbonImmutable::parse($datos['fecha_inicio']);
            $fin = $inicio->addDays($datos['duracion_dias'] - 1);
            $calculo = $this->calculador->calcular($usuario, $evaluacion, $perfil, $inicio->toDateString());
            $this->calculador->calcular($usuario, $evaluacion, $perfil, $fin->toDateString());
            $distribucion = config('alimentacion.distribuciones.'.$datos['cantidad_comidas']);
            if (! is_array($distribucion) || abs(array_sum($distribucion) - 1) > 0.00001 || min($distribucion) <= 0) {
                throw ValidationException::withMessages(['configuracion' => 'Distribucion de comidas invalida.']);
            }
            $candidatos = $this->selector->candidatos($usuarioId);
            $usos = [];
            $comidas = [];
            for ($dia = 1; $dia <= $datos['duracion_dias']; $dia++) {
                $totalesDia = [];
                $orden = 0;
                foreach ($distribucion as $tipo => $fraccion) {
                    $objetivos = array_map(fn ($n) => $n * $fraccion, $calculo['objetivos']);
                    $seleccion = $this->selector->seleccionar($candidatos, $tipo, $objetivos, $usos);
                    $totalesDia[] = $seleccion['totales'];
                    $comidas[] = ['nombre' => ucfirst(str_replace('_', ' ', $tipo)), 'tipo' => $tipo,
                        'orden' => ++$orden, 'hora_sugerida' => $datos['horarios'][$tipo].':00',
                        'dia' => $dia, 'fecha' => $inicio->addDays($dia - 1)->toDateString(),
                        'notas' => 'Menu general sujeto a seguimiento profesional.', 'alimentos' => $seleccion['alimentos']];
                }
                if (! $this->porciones->cumple($this->porciones->sumar($totalesDia), $calculo['objetivos'])) {
                    throw ValidationException::withMessages(['totales' => 'Los totales diarios no cumplen las tolerancias.']);
                }
            }
            $atributos = ['id_usuarios' => $usuarioId, 'id_evaluaciones_fisicas' => $evaluacion->id,
                'nombre' => 'Plan '.$evaluacion->objetivo, 'descripcion' => 'Generacion por reglas '.config('alimentacion.version').'.',
                'objetivo' => $evaluacion->objetivo, 'fecha_inicio' => $inicio->toDateString(), 'fecha_fin' => $fin->toDateString(),
                'estado' => true, 'calculo' => $calculo + ['cantidad_comidas' => (int) $datos['cantidad_comidas'],
                    'duracion_dias' => (int) $datos['duracion_dias'], 'distribucion' => $distribucion]];
            foreach ($calculo['objetivos'] as $nutriente => $valor) {
                $atributos[$nutriente.'_objetivo'] = $valor;
            }
            $plan = PlanAlimentacion::create($atributos);
            foreach ($comidas as $comida) {
                $alimentos = $comida['alimentos'];
                unset($comida['alimentos']);
                $guardada = $plan->comidas()->create($comida);
                $guardada->alimentos()->createMany($alimentos);
            }

            return $plan->load('comidas.alimentos');
        });
    }
}
