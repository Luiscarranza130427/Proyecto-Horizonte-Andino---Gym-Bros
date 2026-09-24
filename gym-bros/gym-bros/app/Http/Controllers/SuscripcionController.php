<?php

namespace App\Http\Controllers;

use App\Http\Resources\SuscripcionResource;
use App\Models\Suscripcion;
use App\Support\Acceso;

class SuscripcionController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return SuscripcionResource::collection(Acceso::limitarPorEmpresa(Suscripcion::query(), $this->actor())->get());
    }
}
