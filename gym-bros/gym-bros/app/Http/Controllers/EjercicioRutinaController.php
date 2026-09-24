<?php

namespace App\Http\Controllers;

use App\Http\Resources\EjercicioRutinaResource;
use App\Models\EjercicioRutina;
use App\Support\Acceso;

class EjercicioRutinaController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return EjercicioRutinaResource::collection(EjercicioRutina::query()->whereIn('id_rutinas',
            Acceso::limitarPorUsuario(\App\Models\Rutina::query()->select('id'), $this->actor()))->get());
    }
}
