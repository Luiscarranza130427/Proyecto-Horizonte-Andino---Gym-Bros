<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MostrarUsuarioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', fn (Blueprint $t) => $t->id());
        DB::table('empresas')->insert(['id' => 1]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        foreach ([1, 2] as $id) {
            DB::table('usuarios')->insert(['id' => $id, 'nombres' => 'Usuario '.$id,
                'apellidos' => 'QA', 'apodo' => 'QA', 'genero' => 'Varon',
                'correo' => 'qa'.$id.'@example.invalid', 'password_hash' => 'secreto-no-exponer',
                'tipo_documento' => 'DNI', 'numero_documento' => '00123456', 'telefono' => '987654321',
                'fecha_registro' => '2026-09-01', 'fecha_nacimiento' => '2000-01-01',
                'inicio_suscripcion' => '2026-09-01', 'fin_suscripcion' => '2026-09-30',
                'tipo_usuario' => 'Usuario', 'estado' => $id === 1, 'id_empresas' => 1]);
        }
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_devuelve_solo_usuario_solicitado_sin_password_ni_escrituras(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        foreach ([1, 2] as $id) {
            $this->get('/api/usuarios/'.$id)->assertOk()->assertJsonPath('data.id', $id)
                ->assertJsonPath('data.nombres', 'Usuario '.$id)
                ->assertJsonPath('data.fin_suscripcion', '2026-09-30')
                ->assertJsonMissingPath('data.password_hash')->assertDontSee('secreto-no-exponer');
        }
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
        $this->getJson('/api/usuarios')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_inexistente_devuelve_json_sin_accept(): void
    {
        $this->get('/api/usuarios/999')->assertNotFound()
            ->assertExactJson(['message' => 'Usuario no encontrado.']);
        $this->getJson('/api/usuarios/0')->assertNotFound();
    }
}
