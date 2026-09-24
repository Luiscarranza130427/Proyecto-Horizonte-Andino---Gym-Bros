<?php

namespace App\Http\Controllers;

use App\Http\Resources\SensacionResource;
use App\Models\Sensacion;
use App\Support\Acceso;

class SensacionController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return SensacionResource::collection(Acceso::limitarPorUsuario(Sensacion::query(), $this->actor())->get());
    }
}
