<?php

namespace App\Http\Controllers;

use App\Http\Resources\NotificacionResource;
use App\Models\Notificacion;
use App\Models\Usuario;
use App\Support\Acceso;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificacionController extends Controller
{
    private const TIPOS = ['recordatorio', 'rutina', 'alimentacion', 'suscripcion', 'sistema', 'otro'];

    /** Recibidas: enviadas y sin leer. */
    public function notificacionesActivas()
    {
        return NotificacionResource::collection($this->visibles()->with(['usuario'])
            ->where('enviada', true)->where('leida', 0)->get());
    }

    public function index(Request $request)
    {
        $filtros = $request->validate([
            'enviada' => ['nullable', 'in:0,1,true,false'],
            'tipo' => ['nullable', Rule::in(self::TIPOS)],
            'search' => ['nullable', 'string', 'max:150'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
        $consulta = $this->visibles()->with('empresa');
        if (($filtros['enviada'] ?? null) !== null) {
            $consulta->where('enviada', in_array($filtros['enviada'], ['1', 'true'], true));
        }
        if (($filtros['tipo'] ?? null) !== null) {
            $consulta->where('tipo', $filtros['tipo']);
        }
        if (($filtros['search'] ?? null) !== null && trim($filtros['search']) !== '') {
            $patron = '%'.addcslashes(trim($filtros['search']), '%_\\').'%';
            $consulta->where(fn ($q) => $q->where('titulo', 'like', $patron)->orWhere('mensaje', 'like', $patron));
        }
        if (isset($filtros['page']) || isset($filtros['per_page'])) {
            return NotificacionResource::collection($consulta->paginate((int) ($filtros['per_page'] ?? 15))->withQueryString());
        }

        return NotificacionResource::collection($consulta->get());
    }

    /** Pendientes de envio, la mas proxima primero. */
    public function programadas()
    {
        return NotificacionResource::collection($this->gestionables()->with('empresa')
            ->where('enviada', false)->reorder()->orderBy('fecha_envio')->orderBy('id')->get());
    }

    /**
     * Comunicado general. El administrador elige `todos` (plataforma) o una
     * empresa; el personal de un gimnasio solo puede escribir a la suya.
     */
    public function store(Request $request)
    {
        $actor = $this->actor();
        $datos = $request->validate([
            'alcance' => ['required', 'in:todos,empresa'],
            'id_empresas' => ['nullable', 'integer', 'exists:empresas,id'],
            'tipo' => ['required', Rule::in(self::TIPOS)],
            'titulo' => ['required', 'string', 'max:150'],
            'mensaje' => ['required', 'string', 'max:2000'],
            'programar' => ['sometimes', 'boolean'],
            'fecha_envio' => ['nullable', 'required_if_accepted:programar', 'date', 'after:now'],
        ]);
        if (Acceso::esAdministrador($actor)) {
            $empresa = $datos['alcance'] === 'empresa' ? ($datos['id_empresas'] ?? null) : null;
            if ($datos['alcance'] === 'empresa' && ! $empresa) {
                return response()->json(['message' => 'Selecciona la empresa destinataria.',
                    'errors' => ['id_empresas' => ['Selecciona la empresa destinataria.']]], 422);
            }
        } else {
            if (isset($datos['id_empresas']) && (string) $datos['id_empresas'] !== (string) $actor->id_empresas) {
                return response()->json(['message' => 'No tiene autorizacion para escribir a otra empresa.'], 403);
            }
            $empresa = $actor->id_empresas;
        }
        $programada = (bool) ($datos['programar'] ?? false);
        $notificacion = Notificacion::create([
            'id_empresas' => $empresa, 'id_usuarios' => null, 'tipo' => $datos['tipo'],
            'titulo' => $datos['titulo'], 'mensaje' => $datos['mensaje'],
            'fecha_envio' => $programada ? $datos['fecha_envio'] : now(),
            'leida' => false, 'enviada' => ! $programada,
        ]);

        return (new NotificacionResource($notificacion->refresh()->load('empresa')))->response()->setStatusCode(201);
    }

    public function enviarAhora(string $id)
    {
        $notificacion = $this->gestionables()->find($id);
        if (! $notificacion) {
            return $this->noEncontrada($id);
        }
        if ($notificacion->enviada) {
            return response()->json(['message' => 'La notificacion ya fue enviada.'], 409);
        }
        $notificacion->forceFill(['enviada' => true, 'fecha_envio' => now()])->save();

        return new NotificacionResource($notificacion->refresh()->load('empresa'));
    }

    /** Solo se retiran avisos aun no enviados: lo enviado es historial. */
    public function destroy(string $id)
    {
        $notificacion = $this->gestionables()->find($id);
        if (! $notificacion) {
            return $this->noEncontrada($id);
        }
        if ($notificacion->enviada) {
            return response()->json(['message' => 'Una notificacion enviada forma parte del historial y no se elimina.'], 409);
        }
        $notificacion->delete();

        return response()->json(['message' => 'Notificacion programada eliminada.', 'data' => ['id' => (int) $id]]);
    }

    /**
     * Administrador: todas. Personal de una empresa: las de su empresa y sus
     * usuarios. Usuario: las suyas y los avisos generales de su empresa o de
     * la plataforma.
     */
    private function visibles(): Builder
    {
        $actor = $this->actor();
        $consulta = Notificacion::query()->orderByDesc('id');
        if (Acceso::esAdministrador($actor)) {
            return $consulta;
        }
        if (Acceso::esPersonal($actor)) {
            return $consulta->where(fn ($q) => $q->where('id_empresas', $actor->id_empresas)
                ->orWhereIn('id_usuarios', Usuario::query()->select('id')->where('id_empresas', $actor->id_empresas)));
        }

        return $consulta->where(fn ($q) => $q->where('id_usuarios', $actor->getKey())
            ->orWhere(fn ($general) => $general->whereNull('id_usuarios')
                ->where(fn ($empresa) => $empresa->whereNull('id_empresas')->orWhere('id_empresas', $actor->id_empresas))));
    }

    /** Lo que el actor puede enviar o retirar: todo (admin) o lo de su empresa. */
    private function gestionables(): Builder
    {
        return Acceso::limitarPorEmpresa(Notificacion::query(), $this->actor());
    }

    private function noEncontrada(string $id)
    {
        // Una notificacion ajena existe pero no es gestionable: 403, no 404.
        return Notificacion::whereKey($id)->exists()
            ? response()->json(['message' => 'No tiene autorizacion para realizar esta accion.'], 403)
            : response()->json(['message' => 'Notificacion no encontrada.'], 404);
    }
}
