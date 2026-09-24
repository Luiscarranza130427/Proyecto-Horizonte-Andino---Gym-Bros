<?php

namespace App\Http\Controllers;

use App\Http\Resources\ComidaAlimentoResource;
use App\Models\ComidaAlimento;
use App\Support\Acceso;

class ComidaAlimentoController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return ComidaAlimentoResource::collection(ComidaAlimento::query()->whereIn('id_comidas', \App\Models\Comida::query()->select('id')
            ->whereIn('id_planes_alimentacion', Acceso::limitarPorUsuario(\App\Models\PlanAlimentacion::query()->select('id'), $this->actor())))->get());
    }
}
