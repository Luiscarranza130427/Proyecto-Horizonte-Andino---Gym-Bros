<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EmpresaUsuariosCountTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        Schema::create('suscripciones', function (Blueprint $table) {
            $table->id(); $table->unsignedBigInteger('id_empresas');
            $table->string('estado'); $table->date('fecha_inicio'); $table->date('fecha_fin');
        });
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->date('fecha_registro');
        });
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('id_empresas')->nullable();
            $table->string('tipo_usuario');
            $table->boolean('estado');
        });
        DB::table('empresas')->insert([
            ['id' => 1, 'nombre' => 'Gym 1', 'fecha_registro' => '2026-09-01'],
            ['id' => 2, 'nombre' => 'Gym 2', 'fecha_registro' => '2026-09-01'],
            ['id' => 3, 'nombre' => 'Sin usuarios', 'fecha_registro' => '2026-09-01'],
        ]);
        DB::table('usuarios')->insert([
            ['id_empresas' => 1, 'tipo_usuario' => 'Administrador', 'estado' => true],
            ['id_empresas' => 1, 'tipo_usuario' => 'Empresa', 'estado' => true],
            ['id_empresas' => 1, 'tipo_usuario' => 'Entrenador', 'estado' => true],
            ['id_empresas' => 1, 'tipo_usuario' => 'Usuario', 'estado' => false],
            ['id_empresas' => 2, 'tipo_usuario' => 'Usuario', 'estado' => true],
            ['id_empresas' => null, 'tipo_usuario' => 'Usuario', 'estado' => true],
        ]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_cuenta_usuarios_por_empresa_incluidos_inactivos_y_cero_sin_listarlos(): void
    {
        $data = $this->getJson('/api/empresas')->assertOk()->assertJsonCount(3, 'data')
            ->assertJsonMissingPath('data.0.usuarios')->json('data');
        $this->assertSame([1 => 4, 2 => 1, 3 => 0], array_column($data, 'cantidad_usuarios', 'id'));
        DB::table('usuarios')->where('id', 4)->update(['id_empresas' => 2]);
        $data = $this->getJson('/api/empresas')->assertOk()->json('data');
        $this->assertSame([1 => 3, 2 => 2, 3 => 0], array_column($data, 'cantidad_usuarios', 'id'));
    }

    public function test_conteo_no_agrega_consultas_por_cada_empresa(): void
    {
        DB::enableQueryLog();
        DB::flushQueryLog();
        $this->getJson('/api/empresas')->assertOk();
        $consultas = collect(DB::getQueryLog())->filter(fn ($query) => str_starts_with(strtolower($query['query']), 'select'));
        $this->assertCount(1, $consultas);
        DB::disableQueryLog();
    }

    public function test_sin_empresas_responde_lista_vacia(): void
    {
        DB::table('usuarios')->delete();
        DB::table('empresas')->delete();
        $this->getJson('/api/empresas')->assertOk()->assertExactJson(['data' => []]);
    }
}
