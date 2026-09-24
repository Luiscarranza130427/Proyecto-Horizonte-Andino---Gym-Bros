<?php

namespace App\Services\Empresa;

use App\Models\Empresa;
use App\Models\Plan;
use App\Models\Suscripcion;
use Illuminate\Validation\ValidationException;

class AsignarPlanEmpresaService
{
    // The caller holds the company lock inside the company write transaction.
    public function asignar(Empresa $empresa, int $idPlan): Suscripcion
    {
        $plan = Plan::whereKey($idPlan)->lockForUpdate()->first();
        $inicio = today();
        if (! $plan || ! $plan->activo || $plan->duracion_dias < 1
            || $plan->duracion_dias > $inicio->diffInDays($inicio->copy()->setDate(9999, 12, 31)) + 1) {
            throw ValidationException::withMessages(['id_planes' => 'Seleccione un plan activo con una duracion valida.']);
        }

        $activas = $empresa->suscripciones()->where('estado', 'activa')->lockForUpdate()->get();
        $vigentes = $activas->filter(fn ($s) => $s->fecha_inicio <= $inicio->toDateString()
            && $s->fecha_fin >= $inicio->toDateString());
        if ($activas->count() === 1 && $vigentes->count() === 1
            && (int) $vigentes->first()->id_planes === $idPlan) {
            return $vigentes->first();
        }

        foreach ($activas as $anterior) {
            $anterior->estado = $anterior->fecha_fin < $inicio->toDateString() ? 'vencida' : 'cancelada';
            if (! $anterior->save()) {
                throw new \RuntimeException('No se pudo actualizar la suscripcion anterior.');
            }
        }

        $suscripcion = new Suscripcion(['id_empresas' => $empresa->id, 'id_planes' => $idPlan,
            'fecha_inicio' => $inicio->toDateString(),
            'fecha_fin' => $inicio->copy()->addDays((int) $plan->duracion_dias - 1)->toDateString(),
            'estado' => 'activa', 'renovacion_automatica' => false]);
        if (! $suscripcion->save()) {
            throw new \RuntimeException('No se pudo crear la suscripcion.');
        }

        return $suscripcion;
    }
}
