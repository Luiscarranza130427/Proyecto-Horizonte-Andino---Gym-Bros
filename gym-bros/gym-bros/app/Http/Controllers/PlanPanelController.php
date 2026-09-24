<?php

namespace App\Http\Controllers;

use App\Http\Resources\ComidaPanelResource;
use App\Http\Resources\PlanPanelResource;
use App\Models\Alimento;
use App\Models\Empresa;
use App\Models\PlanAlimentacion;
use App\Services\Alimentacion\CalculadorPorcionesService;
use App\Support\Acceso;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PlanPanelController extends Controller
{
    private function consulta()
    {
        return Acceso::limitarPorUsuario(PlanAlimentacion::query(), $this->actor());
    }

    public function index(Request $request)
    {
        $datos = $request->validate(['search' => ['nullable', 'string', 'max:150'],
            'activo' => ['nullable', 'in:0,1,true,false'], 'id_empresas' => ['nullable', 'integer', 'min:1'],
            'page' => ['nullable', 'integer', 'min:1'], 'per_page' => ['nullable', 'integer', 'between:1,100']]);
        $query = $this->consulta()->with(['usuario.empresa', 'comidas.alimentos.alimento'])->orderByDesc('id');
        if (isset($datos['activo'])) {
            $query->where('estado', filter_var($datos['activo'], FILTER_VALIDATE_BOOLEAN));
        }
        if (! empty($datos['id_empresas'])) {
            $query->whereHas('usuario', fn ($q) => $q->where('id_empresas', $datos['id_empresas']));
        }
        if (! empty($datos['search'])) {
            $query->whereHas('usuario', fn ($q) => $q->where(function ($nombres) use ($datos) {
                $nombres->where('nombres', 'like', '%'.$datos['search'].'%')->orWhere('apellidos', 'like', '%'.$datos['search'].'%');
            }));
        }

        return PlanPanelResource::collection($query->paginate($datos['per_page'] ?? 10)->withQueryString());
    }

    public function empresas()
    {
        $usuarios = $this->consulta()->select('id_usuarios');

        return response()->json(['data' => Empresa::whereHas('usuarios', fn ($q) => $q->whereIn('id', $usuarios))
            ->orderBy('nombre')->get(['id', 'nombre'])]);
    }

    public function show(string $plan)
    {
        return new PlanPanelResource($this->consulta()->with(['usuario.empresa', 'comidas.alimentos.alimento'])->findOrFail($plan));
    }

    public function guardarComida(Request $request, string $plan, ?string $comida = null)
    {
        $datos = $request->validate([
            'tipo_comida' => ['required', Rule::in(['desayuno', 'media_manana', 'almuerzo', 'media_tarde', 'cena', 'snack', 'otro'])],
            'hora_sugerida' => ['required', 'date_format:H:i,H:i:s'],
            'dia' => ['sometimes', 'integer', 'between:1,366'],
            'alimentos' => ['required', 'array', 'min:1', 'max:50'],
            'alimentos.*.id_alimentos' => ['required', 'integer', 'distinct', Rule::exists('alimentos', 'id')->where('activo', true)],
            'alimentos.*.cantidad' => ['required', 'numeric', 'min:0.01', 'max:999999.99'],
            'alimentos.*.unidad' => ['required', Rule::in(['gramos', 'mililitros', 'unidad'])],
        ]);
        $registro = DB::transaction(function () use ($datos, $plan, $comida) {
            $planActual = $this->consulta()->lockForUpdate()->findOrFail($plan);
            $fila = $comida ? $planActual->comidas()->findOrFail($comida) : $planActual->comidas()->make();
            $dia = $fila->dia ?? ($datos['dia'] ?? 1);
            $fila->fill(['nombre' => $datos['tipo_comida'], 'tipo' => $datos['tipo_comida'],
                'hora_sugerida' => $datos['hora_sugerida'], 'notas' => $fila->notas ?? '', 'dia' => $dia,
                'fecha' => $fila->fecha ?? \Illuminate\Support\Carbon::parse($planActual->fecha_inicio)->addDays($dia - 1)->toDateString(),
                'orden' => $fila->orden ?? (1 + (int) $planActual->comidas()->where('dia', $dia)->max('orden'))]);
            $fila->save();
            $fila->alimentos()->delete();
            foreach ($datos['alimentos'] as $porcion) {
                $alimento = Alimento::findOrFail($porcion['id_alimentos']);
                $nutrientes = app(CalculadorPorcionesService::class)->nutrientes($alimento->toArray(), (float) $porcion['cantidad'], $porcion['unidad']);
                $fila->alimentos()->create($porcion + ['notas' => '', 'detalle_nutricional' => [
                    'nombre' => $alimento->nombre, 'base_cantidad' => 100, 'base_unidad' => $alimento->base_unidad,
                    'estado_preparacion' => $alimento->estado_preparacion, 'fuente' => $alimento->fuente_nutricional,
                    'nutrientes' => $nutrientes]]);
            }

            return $fila->load('alimentos.alimento');
        });

        return (new ComidaPanelResource($registro))->response()->setStatusCode($comida ? 200 : 201);
    }

    public function eliminarComida(string $plan, string $comida)
    {
        return DB::transaction(function () use ($plan, $comida) {
            $registro = $this->consulta()->lockForUpdate()->findOrFail($plan)->comidas()->findOrFail($comida);
            $registro->delete();

            return response()->json(['data' => ['id' => (int) $comida], 'message' => 'Comida eliminada.']);
        });
    }
}
