<?php

namespace App\Http\Controllers;

use App\Http\Resources\PreferenciaAlimentariaResource;
use App\Models\PreferenciaAlimentaria;
use App\Support\Acceso;

class PreferenciaAlimentariaController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return PreferenciaAlimentariaResource::collection(Acceso::limitarPorUsuario(PreferenciaAlimentaria::query(), $this->actor())->get());
    }
}
