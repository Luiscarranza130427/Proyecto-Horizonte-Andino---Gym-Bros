<?php

namespace Tests\Feature;

use Carbon\Carbon;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class VencerSuscripcionesTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-09-15 00:00:00');
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        foreach (['empresas', 'usuarios'] as $table) {
            Schema::create($table, function (Blueprint $t) { $t->id(); $t->boolean('estado'); });
            DB::table($table)->insert([['id' => 1, 'estado' => true], ['id' => 2, 'estado' => false]]);
        }
        Schema::create('planes', function (Blueprint $table) { $table->id(); });
        DB::table('planes')->insert(['id' => 1]);
        (require database_path('migrations/2026_08_21_224533_create_suscripciones.php'))->up();
        foreach ([
            [1, 'activa', '2026-09-14'], [2, 'activa', '2026-09-15'], [3, 'activa', '2026-10-01'],
            [4, 'pendiente', '2026-09-14'], [5, 'cancelada', '2026-09-14'],
            [6, 'suspendida', '2026-09-14'], [7, 'vencida', '2026-09-14'],
            [8, 'activa', '2026-01-01'],
        ] as [$id, $estado, $fin]) {
            DB::table('suscripciones')->insert(['id' => $id, 'id_empresas' => 1, 'id_planes' => 1,
                'fecha_inicio' => '2025-12-01', 'fecha_fin' => $fin, 'estado' => $estado,
                'renovacion_automatica' => true, 'created_at' => '2025-12-01 00:00:00', 'updated_at' => '2025-12-01 00:00:00']);
        }
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_solo_vence_activas_pasadas_sin_cambiar_empresas_usuarios_o_otros_estados(): void
    {
        $empresas = DB::table('empresas')->get()->toJson();
        $usuarios = DB::table('usuarios')->get()->toJson();
        $antes = DB::table('suscripciones')->orderBy('id')->get();
        $this->artisan('suscripciones:vencer')->expectsOutputToContain('Suscripciones vencidas: 2')->assertSuccessful();
        foreach ($antes as $old) {
            $after = DB::table('suscripciones')->find($old->id);
            if (in_array($old->id, [1, 8])) {
                $this->assertSame('vencida', $after->estado);
                unset($old->estado, $old->updated_at, $after->estado, $after->updated_at);
            }
            $this->assertEquals($old, $after);
        }
        $this->assertSame($empresas, DB::table('empresas')->get()->toJson());
        $this->assertSame($usuarios, DB::table('usuarios')->get()->toJson());
        $this->assertDatabaseCount('suscripciones', 8);
    }

    public function test_repetir_no_cambia_registros_y_recupera_vencimientos_atrasados(): void
    {
        $this->artisan('suscripciones:vencer')->assertSuccessful();
        $antes = DB::table('suscripciones')->get()->toJson();
        $this->artisan('suscripciones:vencer')->expectsOutputToContain('Suscripciones vencidas: 0')->assertSuccessful();
        $this->assertSame($antes, DB::table('suscripciones')->get()->toJson());
        Carbon::setTestNow('2026-09-16 10:00:00');
        $this->artisan('suscripciones:vencer')->expectsOutputToContain('Suscripciones vencidas: 1')->assertSuccessful();
        $this->assertDatabaseHas('suscripciones', ['id' => 2, 'estado' => 'vencida']);
        $this->assertDatabaseHas('suscripciones', ['id' => 3, 'estado' => 'activa']);
    }

    public function test_simulacion_y_tabla_vacia_no_modifican_datos(): void
    {
        $antes = DB::table('suscripciones')->get()->toJson();
        $this->artisan('suscripciones:vencer --simular')->expectsOutputToContain('Suscripciones que vencerian: 2')->assertSuccessful();
        $this->assertSame($antes, DB::table('suscripciones')->get()->toJson());
        DB::table('suscripciones')->delete();
        $this->artisan('suscripciones:vencer')->expectsOutputToContain('Suscripciones vencidas: 0')->assertSuccessful();
    }

    public function test_ultimo_dia_completo_es_vigente(): void
    {
        Carbon::setTestNow('2026-09-15 23:59:59');
        $this->artisan('suscripciones:vencer')->assertSuccessful();
        $this->assertDatabaseHas('suscripciones', ['id' => 2, 'estado' => 'activa']);
        Carbon::setTestNow('2026-09-16 00:00:00');
        $this->artisan('suscripciones:vencer')->assertSuccessful();
        $this->assertDatabaseHas('suscripciones', ['id' => 2, 'estado' => 'vencida']);
    }

    public function test_scheduler_registra_una_ejecucion_diaria_sin_solapamiento(): void
    {
        $events = collect(app(Schedule::class)->events())->filter(fn ($e) => str_contains($e->command ?? '', 'suscripciones:vencer'));
        $this->assertCount(1, $events);
        $event = $events->first();
        $this->assertSame('0 0 * * *', $event->expression);
        $this->assertTrue($event->withoutOverlapping);
    }
}
