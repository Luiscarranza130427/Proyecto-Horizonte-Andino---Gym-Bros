<?php

namespace App\Http\Middleware;

use App\Models\Empresa;
use App\Models\Usuario;
use App\Support\Acceso;
use Closure;
use Illuminate\Http\Request;

/**
 * Autoriza por rol y por el usuario o empresa de la URL, para que cambiar un
 * ID en la ruta no de acceso a datos ajenos. Debe ir despues de ApiSesion.
 *
 *   acceso:rol,Administrador,Empresa
 *   acceso:usuario,seguir|gestionar|administrar
 *   acceso:empresa,ver|gestionar
 */
class AutorizarAcceso
{
    public function handle(Request $request, Closure $next, string $tipo, string ...$opciones)
    {
        $actor = $request->user('sanctum');
        if (! $actor instanceof Usuario) {
            return response()->json(['message' => 'Sesion no valida o expirada.'], 401);
        }

        $permitido = match ($tipo) {
            'rol' => Acceso::tieneRol($actor, $opciones),
            'usuario' => $this->usuario($request, $actor, $opciones[0] ?? 'seguir'),
            'empresa' => $this->empresa($request, $actor, $opciones[0] ?? 'ver'),
            default => false,
        };
        if ($permitido === null) {
            return response()->json(['message' => $tipo === 'usuario' ? 'Usuario no encontrado.' : 'Empresa no encontrada.'], 404);
        }
        if (! $permitido) {
            return response()->json(['message' => 'No tiene autorizacion para realizar esta accion.'], 403);
        }

        return $next($request);
    }

    private function usuario(Request $request, Usuario $actor, string $modo): ?bool
    {
        $id = $request->route('id_usuario') ?? $request->route('id');
        $usuario = is_numeric($id) ? Usuario::find($id) : null;
        if (! $usuario) {
            return null;
        }

        return match ($modo) {
            'gestionar' => Acceso::puedeGestionarUsuario($actor, $usuario),
            'administrar' => Acceso::puedeAdministrarUsuario($actor, $usuario),
            default => Acceso::puedeSeguirUsuario($actor, $usuario),
        };
    }

    private function empresa(Request $request, Usuario $actor, string $modo): ?bool
    {
        $id = $request->route('id_empresa') ?? $request->route('empresas');
        $id = $id instanceof Empresa ? $id->getKey() : $id;
        if (! is_numeric($id) || ! Empresa::whereKey($id)->exists()) {
            // Sin revelar si existe una empresa ajena: solo el administrador ve el 404.
            return Acceso::esAdministrador($actor) ? null : false;
        }

        return $modo === 'gestionar'
            ? Acceso::puedeGestionarEmpresa($actor, $id)
            : Acceso::puedeVerEmpresa($actor, $id);
    }
}
