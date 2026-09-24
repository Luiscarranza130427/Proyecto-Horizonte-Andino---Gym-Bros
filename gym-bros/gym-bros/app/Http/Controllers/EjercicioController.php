<?php

namespace App\Http\Controllers;

use App\Http\Resources\EjercicioResource;
use App\Models\Ejercicio;
use App\Models\EmpresaEjercicio;
use App\Http\Requests\StoreEjercicioRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;


class EjercicioController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $actor = $this->actor();
        $seleccion = $request->query('id_empresas');
        $filtros = $request->query();
        foreach (['category', 'level', 'status', 'equipment', 'search'] as $campo) {
            if (isset($filtros[$campo]) && is_string($filtros[$campo])) {
                $valor = trim($filtros[$campo]);
                $filtros[$campo] = $valor === '' ? null : mb_strtolower($valor);
            }
        }
        $validator = Validator::make($filtros, [
            'id_empresas' => ['sometimes', 'required', 'integer', 'min:1', 'exists:empresas,id'],
            'search' => ['nullable', 'string', 'max:200'],
            'category' => ['nullable', 'string', 'max:100'],
            'level' => ['nullable', 'string', 'in:principiante,intermedio,avanzado'],
            'equipment' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', 'in:0,1,true,false,activo,inactivo,active,inactive'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
        if ($validator->fails()) {
            return response()->json(['message' => 'Los filtros de ejercicios no son validos.',
                'errors' => $validator->errors()], 422);
        }
        if ($seleccion !== null && $actor
            && strtolower((string) $actor->tipo_usuario) !== 'administrador'
            && (string) $seleccion !== (string) $actor->id_empresas) {
            return response()->json(['message' => 'No tiene autorizacion para consultar esa empresa.'], 403);
        }
        $filtros = $validator->validated();
        $empresaId = $seleccion ?? $actor?->id_empresas;
        $ejercicios = Ejercicio::query();
        if ($empresaId !== null) {
            $ejercicios->addSelect(['estado_empresa' => EmpresaEjercicio::select('estado')
                ->whereColumn('id_ejercicios', 'ejercicios.id')->where('id_empresas', $empresaId)->limit(1)]);
        }

        // Escape LIKE wildcards so search text remains literal on MySQL and SQLite.
        $contiene = fn ($texto) => '%'.str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $texto).'%';
        if (($filtros['search'] ?? null) !== null) {
            $patron = $contiene($filtros['search']);
            $ejercicios->where(fn ($query) => $query
                ->whereRaw("LOWER(ejercicios.nombre) LIKE ? ESCAPE '!'", [$patron])
                ->orWhereRaw("LOWER(ejercicios.descripcion) LIKE ? ESCAPE '!'", [$patron]));
        }
        if (($filtros['category'] ?? null) !== null) {
            $categoria = $filtros['category'];
            if (in_array($categoria, ['fuerza', 'cardio', 'flexibilidad', 'equilibrio'], true)) {
                $ejercicios->whereRaw('LOWER(ejercicios.tipo) = ?', [$categoria]);
            } else {
                $grupo = fn ($query) => ctype_digit($categoria)
                    ? $query->where('grupos_musculares.id', $categoria)
                    : $query->whereRaw('LOWER(grupos_musculares.descripcion) = ?', [$categoria]);
                $ejercicios->where(fn ($query) => $query->whereHas('grupomuscular', $grupo)
                    ->orWhereHas('gruposMusculares', $grupo));
            }
        }
        if (($filtros['level'] ?? null) !== null) {
            $ejercicios->whereRaw('LOWER(ejercicios.nivel) = ?', [$filtros['level']]);
        }
        if (($filtros['equipment'] ?? null) !== null) {
            $ejercicios->whereRaw("LOWER(ejercicios.equipamiento) LIKE ? ESCAPE '!'", [$contiene($filtros['equipment'])]);
        }
        if (($filtros['status'] ?? null) !== null) {
            $activo = in_array((string) $filtros['status'], ['1', 'true', 'activo', 'active'], true);
            if ($empresaId !== null) {
                $habilitado = fn ($query) => $query->where('empresas.id', $empresaId)
                    ->where('empresa_ejercicio.estado', true);
                $activo ? $ejercicios->whereHas('empresas', $habilitado)
                    : $ejercicios->whereDoesntHave('empresas', $habilitado);
            } else {
                $ejercicios->where('ejercicios.estado', $activo);
            }
        }
        $ejercicios->orderBy('ejercicios.id');
        if (isset($filtros['page']) || isset($filtros['per_page'])) {
            return EjercicioResource::collection($ejercicios
                ->paginate((int) ($filtros['per_page'] ?? 15), ['*'], 'page', (int) ($filtros['page'] ?? 1))
                ->withQueryString());
        }

        return EjercicioResource::collection($ejercicios->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreEjercicioRequest $request)
    {
        $datos = $request->validated();
        $datos['estado'] = (bool) ($datos['estado'] ?? false);
        $ruta = null;
        try {
            $ruta = $request->file('imagen_ejercicio')->store('ejercicios', 'public');
            if (! is_string($ruta) || $ruta === '') {
                throw new \RuntimeException('No se pudo guardar la imagen.');
            }
            $datos['imagen_ejercicio'] = $ruta;
            $ejercicio = DB::transaction(function () use ($datos) {
                $ejercicio = new Ejercicio($datos);
                if (! $ejercicio->save()) {
                    throw new \RuntimeException('No se pudo guardar el ejercicio.');
                }

                $ejercicio->setAttribute('tipo_grupo_muscular', $ejercicio->grupomuscular()->value('tipo'));

                return $ejercicio;
            });
        } catch (\Throwable $exception) {
            if (is_string($ruta) && $ruta !== '') {
                try {
                    Storage::disk('public')->delete($ruta);
                } catch (\Throwable $cleanupException) {
                    report($cleanupException);
                }
            }
            report($exception);

            return response()->json(['message' => 'No se pudo crear el ejercicio.'], 500);
        }

        $ejercicio->setAttribute('imagen_url', $request->getSchemeAndHttpHost().'/storage/'.$ruta);

        return (new EjercicioResource($ejercicio))
            ->response()->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id_ejercicio)
    {
        $ejercicio = Ejercicio::find($id_ejercicio);
        if (! $ejercicio) {
            return response()->json(['message' => 'Ejercicio no encontrado.'], 404);
        }

        return new EjercicioResource($ejercicio);
    }

    public function update(\App\Http\Requests\UpdateEjercicioRequest $request, string $id_ejercicio)
    {
        $ejercicio = Ejercicio::find($id_ejercicio);
        if (! $ejercicio) {
            return response()->json(['message' => 'Ejercicio no encontrado.'], 404);
        }
        $datos = $request->validated();
        $ruta = null;
        try {
            if ($request->hasFile('imagen_ejercicio')) {
                $ruta = $request->file('imagen_ejercicio')->store('ejercicios', 'public');
                if (! is_string($ruta) || $ruta === '') {
                    throw new \RuntimeException('No se pudo guardar la imagen.');
                }
                $datos['imagen_ejercicio'] = $ruta;
            }
            DB::transaction(fn () => $ejercicio->fill($datos)->save() ?: throw new \RuntimeException('No se pudo guardar.'));
        } catch (\Throwable $exception) {
            if ($ruta) {
                Storage::disk('public')->delete($ruta);
            }
            report($exception);

            return response()->json(['message' => 'No se pudo actualizar el ejercicio.'], 500);
        }
        // La imagen anterior se conserva: puede estar referenciada por otros registros.

        return new EjercicioResource($ejercicio->refresh());
    }

    /**
     * Retira el ejercicio del catalogo desactivandolo. No se borra: rutinas ya
     * generadas lo referencian y perderian su historial.
     */
    public function destroy(string $id_ejercicio)
    {
        $ejercicio = Ejercicio::find($id_ejercicio);
        if (! $ejercicio) {
            return response()->json(['message' => 'Ejercicio no encontrado.'], 404);
        }
        $ejercicio->forceFill(['estado' => false])->save();

        return new EjercicioResource($ejercicio->refresh());
    }
}
