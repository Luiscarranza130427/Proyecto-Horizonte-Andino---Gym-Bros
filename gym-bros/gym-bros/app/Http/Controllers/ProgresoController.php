<?php

namespace App\Http\Controllers;

use App\Http\Resources\ProgresoResource;
use App\Models\Progreso;
use App\Support\Acceso;

class ProgresoController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return ProgresoResource::collection(Acceso::limitarPorUsuario(Progreso::query(), $this->actor())->get());
    }
}
