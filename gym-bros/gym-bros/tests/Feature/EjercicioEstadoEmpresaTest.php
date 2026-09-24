<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EjercicioEstadoEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $t) { $t->id(); });
        Schema::create('ejercicios', function (Blueprint $t) { $t->id(); $t->string('nombre'); $t->boolean('estado'); });
        (require database_path('migrations/2026_08_29_170121_create_empresa_ejercicio_table.php'))->up();
        DB::table('empresas')->insert([['id'=>1],['id'=>2]]);
        DB::table('ejercicios')->insert([['id'=>1,'nombre'=>'A','estado'=>1],['id'=>2,'nombre'=>'B','estado'=>0]]);
        DB::table('empresa_ejercicio')->insert([
            ['id_empresas'=>1,'id_ejercicios'=>1,'estado'=>0],
            ['id_empresas'=>2,'id_ejercicios'=>1,'estado'=>1],
        ]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_estado_por_empresa_global_independiente_y_relacion_ausente(): void
    {
        $this->getJson('/api/ejercicios?id_empresas=1')->assertOk()
            ->assertJsonPath('data.0.estado',1)->assertJsonPath('data.0.estado_empresa',false)
            ->assertJsonPath('data.1.estado_empresa',false);
        $this->getJson('/api/ejercicios?id_empresas=2')->assertOk()->assertJsonPath('data.0.estado_empresa',true);
        $this->getJson('/api/ejercicios')->assertOk()->assertJsonPath('data.0.estado_empresa',null);
        $this->assertDatabaseCount('empresa_ejercicio',2);
    }

    public function test_sin_configuracion_inactivo_hasta_activacion_explicita(): void
    {
        $this->getJson('/api/ejercicios?id_empresas=1')->assertOk()->assertJsonPath('data.1.estado_empresa',false);
        $this->putJson('/api/empresas/1/ejercicios/2/estado', ['estado'=>1])->assertOk();
        $this->getJson('/api/ejercicios?id_empresas=1')->assertOk()->assertJsonPath('data.1.estado_empresa',true);
        $this->getJson('/api/ejercicios?id_empresas=2')->assertOk()->assertJsonPath('data.1.estado_empresa',false);
        $this->putJson('/api/empresas/1/ejercicios/2/estado', ['estado'=>0])->assertOk();
        $this->getJson('/api/ejercicios?id_empresas=1')->assertOk()->assertJsonPath('data.1.estado_empresa',false);
    }

    public function test_empresa_autenticada_y_no_permite_suplantar_otra_empresa(): void
    {
        $this->actuarComo(['id'=>20,'id_empresas'=>1,'tipo_usuario'=>'Entrenador']);
        $this->getJson('/api/ejercicios')->assertOk()->assertJsonPath('data.0.estado_empresa',false);
        $this->getJson('/api/ejercicios?id_empresas=2')->assertForbidden();
    }

    public function test_administrador_puede_seleccionar_empresa(): void
    {
        $this->actuarComo(['id'=>20,'tipo_usuario'=>'Administrador']);
        $this->getJson('/api/ejercicios?id_empresas=2')->assertOk()->assertJsonPath('data.0.estado_empresa',true);
    }

    public function test_validacion_json_y_token_simulado_rechazado_en_desarrollo(): void
    {
        foreach (['abc','999','-1'] as $id) {
            $this->get('/api/ejercicios?id_empresas='.$id)->assertUnprocessable()->assertJsonValidationErrors('id_empresas');
        }
        $this->sinSesion();
        $this->app->instance('env', 'local');
        $this->withHeader('Authorization','Bearer simulado')->getJson('https://localhost/api/ejercicios?id_empresas=1')->assertUnauthorized();
    }

    public function test_produccion_rechaza_seleccion_sin_identidad_incluso_con_token_simulado(): void
    {
        $this->sinSesion();
        $this->app->instance('env', 'production');
        $this->getJson('https://localhost/api/ejercicios?id_empresas=1')->assertUnauthorized();
        $this->withHeader('Authorization','Bearer simulado')
            ->getJson('https://localhost/api/ejercicios?id_empresas=1')->assertUnauthorized();
        // Sin HTTPS, produccion rechaza antes de mirar credenciales.
        $this->getJson('http://localhost/api/ejercicios')->assertStatus(400);
    }
}
