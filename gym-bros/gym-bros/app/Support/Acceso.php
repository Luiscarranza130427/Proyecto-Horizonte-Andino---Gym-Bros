<?php

namespace App\Support;

use App\Models\Usuario;
use Illuminate\Contracts\Database\Query\Builder;

/**
 * Reglas de acceso por rol y empresa, compartidas por middleware, gates y
 * controladores para que ningun endpoint decida por su cuenta.
 *
 * - Administrador: plataforma completa.
 * - Empresa: gestiona su empresa y sus usuarios.
 * - Entrenador: consulta y hace seguimiento (evaluaciones, rutinas,
 *   alimentacion) de los usuarios de su empresa, sin editar cuentas.
 * - Usuario: solo sus propios datos.
 */
final class Acceso
{
    public const ADMINISTRADOR = 'administrador';

    public const EMPRESA = 'empresa';

    public const ENTRENADOR = 'entrenador';

    public const USUARIO = 'usuario';

    public static function rol(?Usuario $actor): string
    {
        return mb_strtolower(trim((string) $actor?->tipo_usuario));
    }

    public static function esAdministrador(?Usuario $actor): bool
    {
        return self::rol($actor) === self::ADMINISTRADOR;
    }

    public static function tieneRol(?Usuario $actor, array $roles): bool
    {
        return in_array(self::rol($actor), array_map(fn ($r) => mb_strtolower(trim($r)), $roles), true);
    }

    /** Empresa o Entrenador con empresa asignada: personal de un gimnasio. */
    public static function esPersonal(?Usuario $actor): bool
    {
        return in_array(self::rol($actor), [self::EMPRESA, self::ENTRENADOR], true) && $actor->id_empresas;
    }

    private static function mismaEmpresa(Usuario $actor, $idEmpresa): bool
    {
        return $actor->id_empresas !== null && $idEmpresa !== null
            && (string) $actor->id_empresas === (string) $idEmpresa;
    }

    /** Leer datos y hacer seguimiento (evaluaciones, rutinas, alimentacion). */
    public static function puedeSeguirUsuario(Usuario $actor, Usuario $usuario): bool
    {
        return self::esAdministrador($actor)
            || (string) $actor->getKey() === (string) $usuario->getKey()
            || (self::esPersonal($actor) && self::mismaEmpresa($actor, $usuario->id_empresas));
    }

    /** Editar la cuenta (datos personales, foto). */
    public static function puedeGestionarUsuario(Usuario $actor, Usuario $usuario): bool
    {
        return self::esAdministrador($actor)
            || (string) $actor->getKey() === (string) $usuario->getKey()
            || (self::rol($actor) === self::EMPRESA && self::mismaEmpresa($actor, $usuario->id_empresas));
    }

    /** Activar/desactivar cuentas o cambiar fechas de suscripcion: nunca sobre uno mismo. */
    public static function puedeAdministrarUsuario(Usuario $actor, Usuario $usuario): bool
    {
        if ((string) $actor->getKey() === (string) $usuario->getKey()) {
            return false;
        }

        return self::esAdministrador($actor)
            || (self::rol($actor) === self::EMPRESA && self::mismaEmpresa($actor, $usuario->id_empresas));
    }

    public static function puedeVerEmpresa(Usuario $actor, $idEmpresa): bool
    {
        return self::esAdministrador($actor) || self::mismaEmpresa($actor, $idEmpresa);
    }

    public static function puedeGestionarEmpresa(Usuario $actor, $idEmpresa): bool
    {
        return self::esAdministrador($actor)
            || (self::rol($actor) === self::EMPRESA && self::mismaEmpresa($actor, $idEmpresa));
    }

    /** Filtra una consulta cuyos registros cuelgan de un usuario. */
    public static function limitarPorUsuario(Builder $consulta, Usuario $actor, string $columna = 'id_usuarios'): Builder
    {
        if (self::esAdministrador($actor)) {
            return $consulta;
        }
        if (self::esPersonal($actor)) {
            return $consulta->whereIn($columna, Usuario::query()->select('id')->where('id_empresas', $actor->id_empresas));
        }

        return $consulta->where($columna, $actor->getKey());
    }

    /** Filtra una consulta cuyos registros cuelgan de una empresa. */
    public static function limitarPorEmpresa(Builder $consulta, Usuario $actor, string $columna = 'id_empresas'): Builder
    {
        if (self::esAdministrador($actor)) {
            return $consulta;
        }

        return $actor->id_empresas ? $consulta->where($columna, $actor->id_empresas) : $consulta->whereRaw('1 = 0');
    }
}
