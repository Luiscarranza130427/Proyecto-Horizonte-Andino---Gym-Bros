<?php

namespace App\Services\Empresa;

use App\Models\Empresa;
use App\Models\Usuario;
use Illuminate\Support\Facades\DB;

class EliminarEmpresaService
{
    public function eliminar(string $id): ?array
    {
        return DB::transaction(function () use ($id) {
            $empresa = Empresa::lockForUpdate()->find($id);
            if (! $empresa) {
                return null;
            }
            $usuarios = Usuario::where('id_empresas', $empresa->id)->lockForUpdate()->pluck('id')->all();
            $suscripciones = DB::table('suscripciones')->where('id_empresas', $empresa->id)->lockForUpdate()->pluck('id')->all();
            $rutinas = DB::table('rutinas')->whereIn('id_usuarios', $usuarios)->select('id');
            $evaluaciones = DB::table('evaluaciones_fisicas')->whereIn('id_usuarios', $usuarios)->select('id');

            // Refuse inconsistent cross-company references instead of deleting another tenant's data.
            foreach (['historial_cambios', 'notificaciones'] as $table) {
                if (DB::table($table)->whereIn('id_usuarios', $usuarios)->where('id_empresas', '!=', $empresa->id)->exists()) {
                    throw new \DomainException('Existen referencias de otra empresa a estos usuarios.');
                }
            }
            if (DB::table('pagos')->whereIn('id_suscripciones', $suscripciones)->where('id_empresas', '!=', $empresa->id)->exists()
                || DB::table('sensaciones')->whereIn('id_rutinas', clone $rutinas)->whereNotIn('id_usuarios', $usuarios)->exists()
                || DB::table('planes_alimentacion')->whereIn('id_evaluaciones_fisicas', $evaluaciones)->whereNotIn('id_usuarios', $usuarios)->exists()
                || DB::table('routine_generation_usage')->whereIn('routine_id', clone $rutinas)->whereNotIn('user_id', $usuarios)->exists()) {
                throw new \DomainException('Existen datos relacionados de otros usuarios o empresas.');
            }

            // RESTRICT and SET NULL relations need explicit cleanup before the database cascades.
            DB::table('historial_cambios')->where('id_empresas', $empresa->id)->delete();
            DB::table('notificaciones')->where(function ($query) use ($empresa, $usuarios) {
                $query->where('id_empresas', $empresa->id)->orWhereIn('id_usuarios', $usuarios);
            })->delete();
            // This table has no foreign keys.
            DB::table('routine_generation_usage')->whereIn('user_id', $usuarios)->delete();
            DB::table('suscripciones')->whereIn('id', $suscripciones)->delete();

            if (! $empresa->delete()) {
                throw new \RuntimeException('No se pudo eliminar la empresa.');
            }

            return ['id_empresa' => $empresa->id, 'usuarios_eliminados' => count($usuarios)];
        }, 3);
    }
}
