<?php

namespace Tests;

use App\Models\Usuario;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;

abstract class TestCase extends BaseTestCase
{
    /**
     * Sesion Sanctum de un administrador de plataforma para pruebas de logica
     * de negocio. Las pruebas de permisos usan actuarComo() con el rol real.
     */
    protected function actuarComoAdministrador(): Usuario
    {
        return $this->actuarComo(['id' => 900001, 'tipo_usuario' => 'Administrador', 'id_empresas' => null]);
    }

    /** Actor no persistido: basta para autenticar y decidir permisos por rol y empresa. */
    protected function actuarComo(array $atributos): Usuario
    {
        $usuario = new Usuario;
        $usuario->forceFill($atributos + ['estado' => true, 'correo' => 'qa-actor@gymbros.test',
            'nombres' => '[QA]', 'apellidos' => 'Actor']);
        $usuario->exists = true;
        Sanctum::actingAs($usuario, ['sesion']);

        return $usuario;
    }

    /** Quita la sesion simulada; un Bearer se valida de verdad contra personal_access_tokens. */
    protected function sinSesion(): void
    {
        $this->app['auth']->forgetGuards();
        if (! Schema::hasTable('personal_access_tokens')) {
            (require database_path('migrations/2026_09_22_195900_create_personal_access_tokens.php'))->up();
        }
    }
}
