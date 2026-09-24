<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreEmpresaRequest;
use App\Http\Requests\UpdateEmpresaRequest;
use App\Http\Requests\UpdatePersonalizacionEmpresaRequest;
use App\Http\Requests\UpdateEmpresaLogoRequest;
use App\Http\Requests\DeleteEmpresaRequest;
use App\Services\Empresa\EliminarEmpresaService;
use App\Services\Empresa\AsignarPlanEmpresaService;
use Illuminate\Validation\ValidationException;
use App\Http\Resources\EmpresaResource;
use App\Models\Empresa;
use App\Models\Usuario;
use App\Support\Acceso;
use App\Support\RutaPublica;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class EmpresaController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $hoy = today()->toDateString();
        $empresas = Empresa::withCount('usuarios')->withMax([
            'suscripciones as fecha_fin_suscripcion_activa' => fn ($query) => $query
                ->where('estado', 'activa')->where('fecha_inicio', '<=', $hoy)->where('fecha_fin', '>=', $hoy),
        ], 'fecha_fin');
        if (! Acceso::esAdministrador($actor = $this->actor())) {
            $empresas->whereKey($actor->id_empresas ?? 0);
        }

        return EmpresaResource::collection($empresas->orderBy('id')->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreEmpresaRequest $request, AsignarPlanEmpresaService $asignarPlan)
    {
        $validatedData = $request->validated();
        $idPlan = $validatedData['id_planes'] ?? null;
        unset($validatedData['id_planes']);

        $rutasNuevas = [];
        try {
            foreach (['logo', 'banner_1', 'banner_2', 'banner_3'] as $campo) {
                if ($request->hasFile($campo)) {
                    $ruta = $request->file($campo)->store('empresas', 'public');
                    if (! is_string($ruta) || $ruta === '') {
                        throw new \RuntimeException('No se pudo almacenar la imagen.');
                    }
                    $rutasNuevas[] = $ruta;
                    $validatedData[$campo] = $ruta;
                }
            }
            $empresa = DB::transaction(function () use ($validatedData, $idPlan, $asignarPlan) {
                $empresa = new Empresa($validatedData);
                if (! $empresa->save()) {
                    throw new \RuntimeException('No se pudo crear la empresa.');
                }
                if ($idPlan !== null) {
                    $empresa->setRelation('suscripcionAsignada', $asignarPlan->asignar($empresa, (int) $idPlan));
                }

                return $empresa;
            });
        } catch (\Throwable $exception) {
            foreach ($rutasNuevas as $ruta) {
                try {
                    Storage::disk('public')->delete($ruta);
                } catch (\Throwable $cleanupException) {
                    report($cleanupException);
                }
            }
            if ($exception instanceof ValidationException) {
                return response()->json(['message' => $exception->getMessage(), 'errors' => $exception->errors()], 422);
            }
            report($exception);

            return response()->json(['message' => 'No se pudo guardar la empresa y su suscripcion.'], 500);
        }

        return new EmpresaResource($empresa);
    }




    

    /**
     * Display the specified resource.
     */
    public function show(string $empresas)
    {
        // El parametro de ruta es {empresas}; antes se tipaba `Empresa $empresa`,
        // el binding no coincidia y se devolvia una empresa vacia.
        $empresa = Empresa::find($empresas);
        if (! $empresa) {
            return response()->json(['message' => 'Empresa no encontrada.'], 404);
        }

        return new EmpresaResource($empresa);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateEmpresaRequest $request, string $id_empresa, AsignarPlanEmpresaService $asignarPlan)
    {
        $datos = $request->validated();
        // Plan, estado y fecha de alta los decide la plataforma, no la propia empresa.
        if (! Acceso::esAdministrador($this->actor())
            && array_intersect(array_keys($datos), ['id_planes', 'estado', 'fecha_registro'])) {
            return response()->json(['message' => 'Solo un administrador puede cambiar el plan, el estado o la fecha de registro.'], 403);
        }
        $idPlan = $datos['id_planes'] ?? null;
        unset($datos['id_planes']);
        try {
            $empresa = DB::transaction(function () use ($id_empresa, $datos, $idPlan, $asignarPlan) {
                $empresa = Empresa::whereKey($id_empresa)->lockForUpdate()->first();
                if (! $empresa) {
                    return null;
                }
                if (! $empresa->update($datos)) {
                    throw new \RuntimeException('No se pudo actualizar la empresa.');
                }
                $empresa->refresh();
                if ($idPlan !== null) {
                    $empresa->setRelation('suscripcionAsignada', $asignarPlan->asignar($empresa, (int) $idPlan));
                }

                return $empresa;
            });
        } catch (ValidationException $exception) {
            return response()->json(['message' => $exception->getMessage(), 'errors' => $exception->errors()], 422);
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo guardar la empresa y su suscripcion.'], 500);
        }
        if (! $empresa) {
            return response()->json(['message' => 'Empresa no encontrada.'], 404);
        }

        return new EmpresaResource($empresa);
    }

    public function actualizarPersonalizacion(UpdatePersonalizacionEmpresaRequest $request, string $id_empresa)
    {
        $empresa = Empresa::find($id_empresa);
        if (! $empresa) {
            return response()->json(['message' => 'Empresa no encontrada.'], 404);
        }

        $datos = $request->validated();
        $rutasNuevas = [];
        try {
            foreach (['banner_1', 'banner_2', 'banner_3'] as $campo) {
                if ($request->hasFile($campo)) {
                    $ruta = $request->file($campo)->store('empresas', 'public');
                    if (! is_string($ruta) || $ruta === '') {
                        throw new \RuntimeException('No se pudo almacenar el banner.');
                    }
                    $rutasNuevas[] = $ruta;
                    $datos[$campo] = $ruta;
                }
            }
            DB::transaction(function () use ($empresa, $datos) {
                if (! $empresa->update($datos)) {
                    throw new \RuntimeException('No se pudo guardar la personalizacion.');
                }
            });
        } catch (\Throwable $exception) {
            foreach ($rutasNuevas as $ruta) {
                Storage::disk('public')->delete($ruta);
            }
            throw $exception;
        }

        return new EmpresaResource($empresa->refresh());
    }

    public function actualizarLogo(UpdateEmpresaLogoRequest $request, string $id_empresa)
    {
        $empresa = Empresa::find($id_empresa);
        if (! $empresa) {
            return response()->json(['message' => 'Empresa no encontrada.'], 404);
        }

        $ruta = null;
        try {
            $ruta = $request->file('logo')->store('empresas', 'public');
            if (! is_string($ruta) || $ruta === '') {
                throw new \RuntimeException('No se pudo almacenar el logo.');
            }
            $url = $request->getSchemeAndHttpHost().'/storage/'.$ruta;
            DB::transaction(function () use ($empresa, $ruta) {
                $empresa->logo = $ruta;
                if (! $empresa->save()) {
                    throw new \RuntimeException('No se pudo guardar la ruta del logo.');
                }
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

            return response()->json(['message' => 'No se pudo actualizar el logo de la empresa.'], 500);
        }

        // Existing paths may also be used by banners or other companies.
        // Preserve them; only a failed upload's newly generated file is removed.
        return response()->json(['message' => 'Logo actualizado correctamente.',
            'id_empresa' => $empresa->id, 'logo' => $ruta, 'logo_url' => $url]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(DeleteEmpresaRequest $request, string $id_empresa, EliminarEmpresaService $eliminar)
    {
        try {
            $resultado = $eliminar->eliminar($id_empresa);
        } catch (\DomainException $exception) {
            return response()->json(['message' => 'No se puede eliminar: hay relaciones con otra empresa o usuario. Revise los datos.'], 409);
        } catch (\Illuminate\Database\QueryException $exception) {
            report($exception);
            if (in_array((string) $exception->getCode(), ['23000', '23503'], true)) {
                return response()->json(['message' => 'No se puede eliminar por una dependencia de datos. No se guardaron cambios.'], 409);
            }

            return response()->json(['message' => 'No se pudo eliminar la empresa. No se guardaron cambios.'], 500);
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo eliminar la empresa. No se guardaron cambios.'], 500);
        }
        if ($resultado === null) {
            return response()->json(['message' => 'Empresa no encontrada.'], 404);
        }

        return response()->json(['message' => 'Empresa y usuarios eliminados permanentemente.', 'data' => $resultado]);
    }
#funcio para editar los banners y link boton 

        public function updateBanners(Request $request, $id_empresa)
    {
        $empresa = Empresa::find($id_empresa);

        if (!$empresa) {
            return response()->json([
                'error' => 'Empresa no encontrada'
            ], 404);
        }

        // Solo se actualizan los campos enviados: antes un campo ausente
        // borraba el banner o el enlace guardado.
        $datos = $request->validate([
            'banner_1' => ['sometimes', 'nullable', 'string', 'max:300'],
            'banner_2' => ['sometimes', 'nullable', 'string', 'max:300'],
            'banner_3' => ['sometimes', 'nullable', 'string', 'max:300'],
            'link_boton_1' => ['sometimes', 'nullable', 'string', 'max:200'],
            'link_boton_2' => ['sometimes', 'nullable', 'string', 'max:200'],
            'link_boton_3' => ['sometimes', 'nullable', 'string', 'max:200'],
        ]);
        if ($datos === []) {
            return response()->json(['message' => 'Envie al menos un banner o enlace para actualizar.',
                'errors' => ['datos' => ['Envie al menos un banner o enlace para actualizar.']]], 422);
        }
        $empresa->fill($datos)->save();

        return response()->json([
            'message' => 'Banners actualizados correctamente',
            'id_empresa' => $empresa->id,
            'banner_1' => $empresa->banner_1,
            'banner_2' => $empresa->banner_2,
            'banner_3' => $empresa->banner_3,
            'link_boton_1' => $empresa->link_boton_1,
            'link_boton_2' => $empresa->link_boton_2,
            'link_boton_3' => $empresa->link_boton_3,
        ], 200);
    }

#funcion para mostrar los banners y link boton en movil 
public function banners($id_usuario)
{
    $usuario = Usuario::find($id_usuario);

    if (!$usuario) {
        return response()->json([
            'error' => 'Usuario no encontrado'
        ], 404);
    }

    $empresa = Empresa::find($usuario->id_empresas);

    if (!$empresa) {
        return response()->json([
            'error' => 'Empresa no encontrada',
            'id_empresa_usuario' => $usuario->id_empresas
        ], 404);
    }

    return response()->json([
        'id_usuario' => $usuario->id,
        'id_empresa' => $empresa->id,

        'banner_1' => $empresa->banner_1,
        'banner_2' => $empresa->banner_2,
        'banner_3' => $empresa->banner_3,
        'banner_1_url' => RutaPublica::url($empresa->banner_1),
        'banner_2_url' => RutaPublica::url($empresa->banner_2),
        'banner_3_url' => RutaPublica::url($empresa->banner_3),

        'link_boton_1' => $empresa->link_boton_1,
        'link_boton_2' => $empresa->link_boton_2,
        'link_boton_3' => $empresa->link_boton_3,
    ], 200);
}
    }
