<?php

namespace Tests\Feature;

use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EstadoSuscripcionEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        Carbon::setTestNow('2026-09-15 18:00:00');
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $t) { $t->id(); $t->boolean('estado'); });
        Schema::create('usuarios', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('id_empresas'); });
        Schema::create('suscripciones', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('id_empresas'); $t->string('estado');
            $t->date('fecha_inicio'); $t->date('fecha_fin');
        });
        DB::table('empresas')->insert([['id' => 1, 'estado' => true], ['id' => 2, 'estado' => false]]);
        DB::table('usuarios')->insert(['id_empresas' => 1]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_estados_y_limite_estricto_de_siete_dias_sin_escrituras(): void
    {
        $this->getJson('/api/empresas')->assertOk()->assertJsonPath('data.0.estado_suscripcion', 'Inactivo');
        foreach ([
            ['activa', '2026-09-01', '2026-09-23', 'Activo'],
            ['activa', '2026-09-01', '2026-09-22', 'Activo'],
            ['activa', '2026-09-01', '2026-09-21', 'Por Vencer'],
            ['activa', '2026-09-01', '2026-09-16', 'Por Vencer'],
            ['activa', '2026-09-01', '2026-09-15', 'Por Vencer'],
            ['activa', '2026-09-01', '2026-09-14', 'Inactivo'],
            ['activa', '2026-09-16', '2026-09-30', 'Inactivo'],
            ['vencida', '2026-09-01', '2026-09-30', 'Inactivo'],
            ['pendiente', '2026-09-01', '2026-09-30', 'Inactivo'],
            ['cancelada', '2026-09-01', '2026-09-30', 'Inactivo'],
            ['suspendida', '2026-09-01', '2026-09-30', 'Inactivo'],
        ] as [$estado, $inicio, $fin, $esperado]) {
            DB::table('suscripciones')->delete();
            DB::table('suscripciones')->insert(['id_empresas' => 1, 'estado' => $estado, 'fecha_inicio' => $inicio, 'fecha_fin' => $fin]);
            $antes = DB::table('suscripciones')->get()->toJson();
            $this->getJson('/api/empresas')->assertOk()->assertJsonPath('data.0.estado_suscripcion', $esperado)
                ->assertJsonPath('data.0.cantidad_usuarios', 1)->assertJsonPath('data.0.estado', 1)
                ->assertJsonPath('data.1.estado_suscripcion', 'Inactivo');
            $this->assertSame($antes, DB::table('suscripciones')->get()->toJson());
        }
    }

    public function test_varias_suscripciones_no_ocultan_una_vigente_ni_mezclan_empresas(): void
    {
        foreach (['2026-09-14', '2026-09-16', '2026-10-01'] as $fin) {
            DB::table('suscripciones')->insert(['id_empresas' => 1, 'estado' => 'activa', 'fecha_inicio' => '2026-09-01', 'fecha_fin' => $fin]);
        }
        DB::table('suscripciones')->insert(['id_empresas' => 2, 'estado' => 'activa', 'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-09-16']);
        $this->getJson('/api/empresas')->assertOk()->assertJsonPath('data.0.estado_suscripcion', 'Activo')
            ->assertJsonPath('data.1.estado_suscripcion', 'Por Vencer')->assertJsonPath('data.1.estado', 0);
    }

    public function test_calcula_por_dia_no_por_horas_y_cambia_al_pasar_medianoche(): void
    {
        DB::table('suscripciones')->insert(['id_empresas' => 1, 'estado' => 'activa', 'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-09-22']);
        Carbon::setTestNow('2026-09-15 23:59:59');
        $this->getJson('/api/empresas')->assertOk()->assertJsonPath('data.0.estado_suscripcion', 'Activo');
        Carbon::setTestNow('2026-09-16 00:00:00');
        $this->getJson('/api/empresas')->assertOk()->assertJsonPath('data.0.estado_suscripcion', 'Por Vencer');
    }
}
