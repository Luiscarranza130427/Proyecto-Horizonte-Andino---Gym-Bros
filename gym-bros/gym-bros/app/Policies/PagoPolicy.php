<?php

namespace App\Policies;

use App\Models\{Pago,Usuario};

class PagoPolicy
{
    public function reembolsar(Usuario $usuario, Pago $pago): bool
    {
        return (bool) $usuario->estado && in_array(strtolower($usuario->tipo_usuario),['empresa','administrador'],true)
            && (int) $usuario->id_empresas === (int) $pago->id_empresas
            && $usuario->tokenCan('pagos:reembolsar');
    }
}
