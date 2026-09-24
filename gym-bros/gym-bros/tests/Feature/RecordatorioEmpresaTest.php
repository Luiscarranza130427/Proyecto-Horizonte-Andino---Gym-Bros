<?php

namespace Tests\Feature;

use App\Models\Notificacion;
use Carbon\CarbonImmutable;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class RecordatorioEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:', 'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-22 02:00','UTC'));
        Schema::create('empresas', function (Blueprint $t) { $t->id(); $t->string('nombre'); });
        Schema::create('usuarios', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('id_empresas')->nullable(); $t->string('tipo_usuario'); });
        Schema::create('suscripciones', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('id_empresas'); $t->string('estado'); $t->date('fecha_inicio'); $t->date('fecha_fin');
        });
        (require database_path('migrations/2026_08_21_224516_create_notificaciones.php'))->up();
        (require database_path('migrations/2026_09_21_180000_add_datos_to_notificaciones.php'))->up();
        DB::table('empresas')->insert([['id'=>1,'nombre'=>'Uno'],['id'=>2,'nombre'=>'Dos']]);
        foreach ([[1,'empresa'],[2,'empresa'],[1,'entrenador'],[1,'cliente'],[null,'administrador'],[2,'Administrador'],[1,'empresa']] as [$empresa,$tipo]) {
            DB::table('usuarios')->insert(['id_empresas'=>$empresa,'tipo_usuario'=>$tipo]);
        }
        Mail::fake();
    }

    protected function tearDown(): void
    {
        Notificacion::flushEventListeners();
        CarbonImmutable::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function suscripcion(int $empresa, int $dias, string $estado = 'activa', string $inicio = '2026-09-01'): void
    {
        DB::table('suscripciones')->insert(['id_empresas'=>$empresa,'estado'=>$estado,'fecha_inicio'=>$inicio,
            'fecha_fin'=>CarbonImmutable::today('America/Lima')->addDays($dias)->toDateString()]);
    }

    public function test_destinatarios_datos_diarios_y_duplicados(): void
    {
        $this->suscripcion(1,7); $this->suscripcion(2,1);
        $this->artisan('empresas:recordar-suscripcion --simular')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',0);
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',7);
        $this->assertEquals([1,5,6,7],Notificacion::where('id_empresas',1)->orderBy('id_usuarios')->pluck('id_usuarios')->all());
        $this->assertEquals([2,5,6],Notificacion::where('id_empresas',2)->orderBy('id_usuarios')->pluck('id_usuarios')->all());
        $n = Notificacion::where('id_empresas',1)->first();
        $this->assertSame(7,$n->datos['dias_restantes']);
        $this->assertSame('2026-09-28',$n->datos['fecha_fin']);
        $this->assertSame('Uno',$n->datos['nombre_empresa']);
        $this->assertNull($n->datos['url_renovacion']);
        $n->update(['leida'=>true]);
        $antes=DB::table('notificaciones')->get()->toJson();
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertSame($antes,DB::table('notificaciones')->get()->toJson());
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-22 10:00','America/Lima'));
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',11);
        Mail::assertNothingSent();
    }

    public function test_limites_estados_y_renovacion(): void
    {
        foreach ([-1,0,8] as $dias) { $this->suscripcion(1,$dias); }
        $this->suscripcion(2,4,'cancelada');
        $this->suscripcion(2,5,'activa','2026-09-23');
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',0);
        DB::table('suscripciones')->delete();
        $this->suscripcion(1,3); $this->suscripcion(1,30);
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',0);
        Mail::assertNothingSent();
    }

    public function test_fallo_revierte_empresa_y_reintento(): void
    {
        $this->suscripcion(1,2);
        Notificacion::saved(function () { throw new \RuntimeException('QA'); });
        $this->artisan('empresas:recordar-suscripcion')->assertFailed();
        $this->assertDatabaseCount('notificaciones',0);
        Notificacion::flushEventListeners();
        $this->artisan('empresas:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',4);
    }
}
