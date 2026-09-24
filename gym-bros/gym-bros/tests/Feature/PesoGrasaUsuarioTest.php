<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PesoGrasaUsuarioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());

        // Minimal read-only fixtures for this endpoint, isolated from the local MySQL database.
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
        });
        Schema::create('evaluaciones_fisicas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_usuarios')->constrained('usuarios');
            $table->decimal('peso', 6, 2);
            $table->decimal('porcentaje_grasa', 5, 2);
            $table->date('fecha_evaluacion');
        });
        DB::table('usuarios')->insert([['id' => 1], ['id' => 2]]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_returns_latest_measurements_for_requested_user_without_writes(): void
    {
        DB::table('evaluaciones_fisicas')->insert([
            ['id' => 1, 'id_usuarios' => 1, 'peso' => 72.35, 'porcentaje_grasa' => 18.75, 'fecha_evaluacion' => '2026-09-09'],
            ['id' => 2, 'id_usuarios' => 1, 'peso' => 80, 'porcentaje_grasa' => 25, 'fecha_evaluacion' => '2026-09-01'],
            ['id' => 3, 'id_usuarios' => 2, 'peso' => 90, 'porcentaje_grasa' => 30, 'fecha_evaluacion' => '2026-09-09'],
        ]);
        $before = DB::table('evaluaciones_fisicas')->orderBy('id')->get()->toJson();
        $this->getJson('/api/usuarios/1/evaluaciones/peso-grasa')->assertOk()->assertExactJson([
            'data' => ['id_usuarios' => 1, 'id_evaluacion' => 1, 'fecha_evaluacion' => '2026-09-09',
                'peso' => 72.35, 'porcentaje_grasa' => 18.75],
        ]);
        $this->assertSame($before, DB::table('evaluaciones_fisicas')->orderBy('id')->get()->toJson());
    }

    public function test_same_date_uses_highest_id_and_keeps_zero_values(): void
    {
        DB::table('evaluaciones_fisicas')->insert([
            ['id' => 1, 'id_usuarios' => 1, 'peso' => 72.35, 'porcentaje_grasa' => 18.75, 'fecha_evaluacion' => '2026-09-09'],
            ['id' => 2, 'id_usuarios' => 1, 'peso' => 70.25, 'porcentaje_grasa' => 0, 'fecha_evaluacion' => '2026-09-09'],
        ]);
        $response = $this->getJson('/api/usuarios/1/evaluaciones/peso-grasa')->assertOk()
            ->assertJsonPath('data.id_evaluacion', 2)->assertJsonPath('data.peso', 70.25);
        $this->assertEquals(0, $response->json('data.porcentaje_grasa'));
        $this->assertIsNumeric($response->json('data.porcentaje_grasa'));
    }

    public function test_existing_user_without_evaluation_gets_a_clear_error(): void
    {
        DB::table('evaluaciones_fisicas')->insert(['id_usuarios' => 2, 'peso' => 70,
            'porcentaje_grasa' => 20, 'fecha_evaluacion' => '2026-09-09']);
        $this->getJson('/api/usuarios/1/evaluaciones/peso-grasa')->assertNotFound()
            ->assertJsonPath('message', 'El usuario no tiene evaluaciones fisicas registradas.');
    }

    public function test_nonexistent_user_gets_not_found(): void
    {
        $this->getJson('/api/usuarios/999/evaluaciones/peso-grasa')->assertNotFound();
    }

    public function test_invalid_identifiers_are_rejected(): void
    {
        foreach (['abc', '-1', '1.5', '0'] as $id) {
            $this->getJson('/api/usuarios/'.$id.'/evaluaciones/peso-grasa')->assertNotFound();
        }
    }
}
