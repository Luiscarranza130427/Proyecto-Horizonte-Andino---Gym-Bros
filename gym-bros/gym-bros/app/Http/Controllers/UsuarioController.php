<?php

namespace App\Http\Controllers;
use App\Models\Empresa;
use App\Http\Resources\UsuarioResource;
use App\Models\Usuario;
use App\Support\Acceso;
use App\Http\Requests\UpdateUsuarioFotoRequest;
use App\Http\Requests\UpdateUsuarioRequest;
use App\Http\Requests\UpdateUsuarioEstadoRequest;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class UsuarioController extends Controller
{
    public function exportar(Request $request)
    {
        $actor = $request->user('sanctum');
        if (! $actor instanceof Usuario) {
            return response()->json(['message' => 'Se requiere autenticacion.'], 401);
        }
        if (! $actor->estado || ! in_array($actor->tipo_usuario, ['Administrador', 'Empresa'], true)) {
            return response()->json(['message' => 'No tiene permiso para exportar usuarios.'], 403);
        }

        $campos = ['id','nombres','apellidos','apodo','genero','correo','tipo_documento',
            'numero_documento','telefono','direccion','fecha_registro','fecha_nacimiento',
            'inicio_suscripcion','fin_suscripcion','tipo_usuario','estado','id_empresas'];
        $usuarios = Usuario::query()->select($campos);
        if ($actor->tipo_usuario === 'Empresa') {
            if (! $actor->id_empresas || ! $actor->empresa()->exists()) {
                return response()->json(['message' => 'El usuario no tiene una empresa asociada.'], 403);
            }
            $usuarios->where('id_empresas', $actor->id_empresas);
        }

        return response()->streamDownload(function () use ($usuarios, $campos) {
            $salida = fopen('php://output', 'w');
            fwrite($salida, "\xEF\xBB\xBF");
            fputcsv($salida, $campos, ';', '"', '');
            foreach ($usuarios->lazyById(500) as $usuario) {
                $fila = [];
                foreach ($campos as $campo) {
                    $valor = (string) ($usuario->getRawOriginal($campo) ?? '');
                    // Neutralize spreadsheet formulas, including whitespace-prefixed ones.
                    if (preg_match('/^[\s\x{FEFF}]*[=+@-]/u', $valor) || preg_match('/^[\t\r\n]/', $valor)) {
                        $valor = "'".$valor;
                    }
                    $fila[] = $valor;
                }
                fputcsv($salida, $fila, ';', '"', '');
            }
            fclose($salida);
        }, 'usuarios-'.now()->format('Y-m-d-His').'.csv', [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Cache-Control' => 'private, no-store',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function actualizarEstado(UpdateUsuarioEstadoRequest $request, string $id_usuario)
    {
        try {
            $usuario = DB::transaction(function () use ($request, $id_usuario) {
                $usuario = Usuario::whereKey($id_usuario)->lockForUpdate()->first();
                if (! $usuario) {
                    return null;
                }
                $usuario->estado = (bool) $request->validated('estado');
                if (! $usuario->save()) {
                    throw new \RuntimeException('No se pudo guardar el estado.');
                }

                return $usuario;
            });
        } catch (\Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'No se pudo actualizar el estado del usuario.'], 500);
        }
        if (! $usuario) {
            return response()->json(['message' => 'Usuario no encontrado.'], 404);
        }

        return response()->json(['message' => 'Estado actualizado correctamente.',
            'id_usuario' => $usuario->id, 'estado' => (bool) $usuario->estado]);
    }

    public function actualizarFoto(UpdateUsuarioFotoRequest $request, string $id_usuario)
    {
        $usuario = Usuario::find($id_usuario);

        if (! $usuario) {
            return response()->json(['error' => 'Usuario no encontrado'], 404);
        }

        $rutaNueva = null;
        try {
            $rutaNueva = $request->file('foto_perfil')->store('usuario', 'public');
            if (! is_string($rutaNueva) || $rutaNueva === '') {
                throw new \RuntimeException('No se pudo almacenar la imagen.');
            }
            $url = $request->getSchemeAndHttpHost().'/storage/'.$rutaNueva;
            DB::transaction(function () use ($usuario, $rutaNueva) {
                $usuario->foto_perfil = $rutaNueva;
                if (! $usuario->save()) {
                    throw new \RuntimeException('No se pudo guardar la imagen de perfil.');
                }
            });
        } catch (\Throwable $exception) {
            if (is_string($rutaNueva) && $rutaNueva !== '') {
                try {
                    Storage::disk('public')->delete($rutaNueva);
                } catch (\Throwable $cleanupException) {
                    report($cleanupException);
                }
            }
            report($exception);

            return response()->json(['message' => 'No se pudo actualizar la imagen de perfil.'], 500);
        }

        // Preserve previous files, which may be shared, as with company logos.
        return response()->json([
            'message' => 'Imagen de perfil actualizada correctamente',
            'id_usuario' => $usuario->id,
            'foto_perfil' => $rutaNueva,
            'foto_url' => $url,
        ], 200);
    }

    /**
     * Display a listing of the resource.
     */
    /**
     * Alta individual desde el panel. Como en la importacion, la cuenta nace
     * sin contrasena utilizable y el titular recibe el enlace para crearla.
     * El administrador elige empresa y rol; una Empresa solo da de alta
     * Entrenadores y Usuarios en la suya.
     */
    public function store(Request $request)
    {
        $actor = $this->actor();
        $admin = Acceso::esAdministrador($actor);
        $datos = $request->validate([
            'nombres' => ['required', 'string', 'max:100'],
            'apellidos' => ['required', 'string', 'max:100'],
            'apodo' => ['required', 'string', 'max:100'],
            'genero' => ['required', 'in:Varon,Mujer'],
            'correo' => ['required', 'email', 'max:255', 'not_regex:/[\x00-\x1F\x7F]/'],
            'tipo_documento' => ['required', 'in:DNI,PASAPORTE,OTRO'],
            'numero_documento' => ['required', 'string', 'max:12'],
            'telefono' => ['required', 'string', 'max:12'],
            'direccion' => ['nullable', 'string', 'max:150'],
            'fecha_nacimiento' => ['required', 'date_format:Y-m-d', 'after_or_equal:1900-01-01', 'before_or_equal:today'],
            'inicio_suscripcion' => ['nullable', 'date_format:Y-m-d'],
            'fin_suscripcion' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:inicio_suscripcion'],
            'tipo_usuario' => ['required', $admin ? 'in:Administrador,Empresa,Entrenador,Usuario' : 'in:Entrenador,Usuario'],
            'estado' => ['sometimes', 'boolean'],
            'id_empresas' => [$admin ? 'required' : 'nullable', 'integer', 'exists:empresas,id'],
        ]);
        $datos['correo'] = mb_strtolower(trim($datos['correo']));
        if (! $admin) {
            if (isset($datos['id_empresas']) && (string) $datos['id_empresas'] !== (string) $actor->id_empresas) {
                return response()->json(['message' => 'Solo puede crear usuarios en su propia empresa.'], 403);
            }
            $datos['id_empresas'] = $actor->id_empresas;
        }
        if (Usuario::whereRaw('LOWER(TRIM(correo)) = ?', [$datos['correo']])->exists()) {
            return response()->json(['message' => 'El correo ya esta registrado.',
                'errors' => ['correo' => ['El correo ya esta registrado.']]], 422);
        }

        try {
            $usuario = DB::transaction(function () use ($datos) {
                $usuario = new Usuario();
                $usuario->forceFill($datos + [
                    'estado' => true,
                    'fecha_registro' => now()->toDateString(),
                    // Sin contrasena utilizable hasta que el titular siga el enlace del correo.
                    'password_hash' => '!pendiente:'.\Illuminate\Support\Str::random(64),
                ])->save();
                \Illuminate\Support\Facades\Queue::connection('database')->push(
                    (new \App\Jobs\ProcesarRecuperacionPassword($datos['correo'], true))->beforeCommit(),
                    '', 'recuperacion-password');

                return $usuario;
            });
        } catch (\Illuminate\Database\UniqueConstraintViolationException) {
            return response()->json(['message' => 'El correo ya esta registrado.',
                'errors' => ['correo' => ['El correo ya esta registrado.']]], 422);
        }

        return (new UsuarioResource($usuario->refresh()))->response()->setStatusCode(201);
    }

    /** Cambios sobre la cuenta y acciones realizadas por el usuario (historial_cambios). */
    public function historial(string $id_usuario)
    {
        $eventos = \App\Models\HistorialCambio::query()
            ->where(fn ($q) => $q->where(fn ($r) => $r->where('tabla_afectada', 'usuarios')->where('id_registros', $id_usuario))
                ->orWhere('id_usuarios', $id_usuario))
            ->orderByDesc('created_at')->orderByDesc('id')->limit(200)->get();
        $autores = Usuario::whereIn('id', $eventos->pluck('id_usuarios')->filter()->unique())->get()->keyBy('id');

        return response()->json(['data' => $eventos->map(fn ($e) => [
            'id' => $e->id,
            'fecha' => $e->created_at,
            'accion' => $e->accion,
            'tabla' => $e->tabla_afectada,
            'descripcion' => $e->descripcion,
            'autor' => ['id' => $e->id_usuarios,
                'nombre' => trim(($autores[$e->id_usuarios]->nombres ?? '').' '.($autores[$e->id_usuarios]->apellidos ?? ''))],
        ])->values()]);
    }

    public function index()
    {
        $actor = $this->actor();
        $usuarios = Usuario::query()->orderBy('id');
        if (! Acceso::esAdministrador($actor)) {
            Acceso::esPersonal($actor)
                ? $usuarios->where('id_empresas', $actor->id_empresas)
                : $usuarios->whereKey($actor->getKey());
        }

        return UsuarioResource::collection($usuarios->get());
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id_usuario)
    {
        $usuario = Usuario::find($id_usuario);
        if (! $usuario) {
            return response()->json(['message' => 'Usuario no encontrado.'], 404);
        }

        return new UsuarioResource($usuario);
    }






public function empresaUsuario($id_usuario)
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
            'error' => 'Empresa no encontrada'
        ], 404);
    }

    return response()->json([
        'id_usuario' => $usuario->id,
        'nombres' => $usuario->nombres,
        'apellidos' => $usuario->apellidos,
        'apodo' => $usuario->apodo,
        'fecha_registro' => $usuario->created_at,
        'empresa' => $empresa->nombre,
        'logo' => $empresa->logo,
        'logo_url' => \App\Support\RutaPublica::url($empresa->logo),
    ], 200);
}






# editar datos usuario
public function update(UpdateUsuarioRequest $request, $id_usuario)
{
    $usuario = Usuario::find($id_usuario);

    if (!$usuario) {
        return response()->json([
            'error' => 'Usuario no encontrado'
        ], 404);
    }

    // Las fechas de suscripcion deciden el acceso pagado: el propio usuario no
    // puede extenderlas, solo el administrador o su empresa.
    $datos = $request->validated();
    // Rol, estado y empresa no se editan aqui (el estado tiene su endpoint). Las
    // fechas de suscripcion deciden el acceso pagado: el propio usuario no puede
    // extenderlas, solo el administrador o su empresa.
    foreach (['inicio_suscripcion', 'fin_suscripcion'] as $campo) {
        if (array_key_exists($campo, $datos) && (string) $datos[$campo] === (string) $usuario->getRawOriginal($campo)) {
            unset($datos[$campo]); // El formulario reenvia el valor actual: no es un cambio.
        }
    }
    if (array_intersect(array_keys($datos), ['inicio_suscripcion', 'fin_suscripcion'])
        && ! Acceso::puedeAdministrarUsuario($this->actor(), $usuario)) {
        return response()->json(['message' => 'No tiene autorizacion para modificar la suscripcion del usuario.'], 403);
    }

    try {
        DB::transaction(function () use ($usuario, $datos) {
            if (! $usuario->update($datos)) {
                throw new \RuntimeException('No se pudo guardar el usuario.');
            }
        });
    } catch (\Throwable $exception) {
        report($exception);

        return response()->json(['message' => 'No se pudieron actualizar los datos del usuario.'], 500);
    }

    return response()->json([
        'message' => 'Datos actualizados correctamente',
        'id_usuario' => $usuario->id,
        'nombre' => $usuario->nombres,
        'apellidos' => $usuario->apellidos,
        'apodo' => $usuario->apodo,
        'correo' => $usuario->correo,
        'telefono' => $usuario->telefono,
        'tipo_documento' => $usuario->tipo_documento,
        'numero_documento' => $usuario->numero_documento,
        'genero' => $usuario->genero,
        'fecha_nacimiento' => $usuario->fecha_nacimiento,
        'direccion' => $usuario->direccion,
    ], 200);
}




}
