<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ActualizarEstadoUsuarioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('nombres');
            $table->boolean('estado');
            $table->timestamps();
        });
        DB::table('usuarios')->insert([
            ['id' => 1, 'nombres' => 'Uno', 'estado' => true],
            ['id' => 2, 'nombres' => 'Dos', 'estado' => true],
        ]);
    }

    protected function tearDown(): void
    {
        Usuario::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_activa_desactiva_y_reintenta_sin_modificar_otros_datos(): void
    {
        $other = DB::table('usuarios')->find(2);
        foreach ([0, 0, 1, false, true, '0', '1'] as $estado) {
            $this->putJson('/api/usuarios/1/estado', ['estado' => $estado, 'nombres' => 'No cambiar', 'id' => 2])
                ->assertOk()->assertJsonPath('id_usuario', 1)->assertJsonPath('estado', (bool) $estado);
            $this->assertDatabaseHas('usuarios', ['id' => 1, 'estado' => (bool) $estado, 'nombres' => 'Uno']);
        }
        $this->assertEquals($other, DB::table('usuarios')->find(2));
    }

    public function test_invalidos_sin_accept_devuelven_json_y_no_guardan(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        foreach ([[], ['estado' => null], ['estado' => 2], ['estado' => 'activo'], ['estado' => 'false'], ['estado' => []]] as $data) {
            $this->put('/api/usuarios/1/estado', $data)->assertUnprocessable()->assertJsonValidationErrors('estado');
        }
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
    }

    public function test_usuario_inexistente(): void
    {
        $this->putJson('/api/usuarios/999/estado', ['estado' => false])->assertNotFound()->assertJsonStructure(['message']);
    }

    public function test_fallo_al_guardar_revierte_el_cambio(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        Usuario::saved(function () { throw new \RuntimeException('Error privado QA'); });
        $this->put('/api/usuarios/1/estado', ['estado' => false])->assertStatus(500)
            ->assertExactJson(['message' => 'No se pudo actualizar el estado del usuario.']);
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
    }
}
