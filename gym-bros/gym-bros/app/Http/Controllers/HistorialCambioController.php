<?php

namespace App\Http\Controllers;

use App\Http\Resources\HistorialCambioResource;
use App\Models\HistorialCambio;
use App\Support\Acceso;

class HistorialCambioController extends Controller
{
    /** Listado limitado a lo que el rol puede ver: todo, su empresa o solo lo propio. */
    public function index()
    {
        return HistorialCambioResource::collection(Acceso::limitarPorEmpresa(HistorialCambio::query(), $this->actor())->get());
    }
}
