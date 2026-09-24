<?php

namespace App\Http\Controllers;

use App\Models\Usuario;

abstract class Controller
{
    /** Usuario autenticado por el middleware `sesion`. */
    protected function actor(): Usuario
    {
        $actor = request()->user('sanctum');
        abort_unless($actor instanceof Usuario, 401, 'Sesion no valida o expirada.');

        return $actor;
    }
}
