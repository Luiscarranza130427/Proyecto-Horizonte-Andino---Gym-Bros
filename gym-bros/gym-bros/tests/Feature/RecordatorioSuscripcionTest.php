<?php

namespace Tests\Feature;

use App\Http\Resources\NotificacionResource;
use App\Models\Notificacion;
use Carbon\CarbonImmutable;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class RecordatorioSuscripcionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null, 'mail.default'=>'smtp']);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-21 10:00:00', 'America/Lima'));
        Schema::create('empresas', function (Blueprint $t) {
            $t->id(); $t->string('nombre'); $t->string('telefono')->nullable();
        });
        Schema::create('usuarios', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('id_empresas')->nullable(); $t->string('nombres');
            $t->string('correo')->nullable(); $t->date('fin_suscripcion')->nullable();
            $t->boolean('estado')->default(true);
        });
        (require database_path('migrations/2026_08_21_224516_create_notificaciones.php'))->up();
        (require database_path('migrations/2026_09_21_180000_add_datos_to_notificaciones.php'))->up();
        DB::table('empresas')->insert(['id'=>1,'nombre'=>'Gimnasio QA','telefono'=>'987 654 321']);
        Mail::fake();
    }

    protected function tearDown(): void
    {
        Notificacion::flushEventListeners();
        CarbonImmutable::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function usuario(?int $dias, array $extra = []): int
    {
        return DB::table('usuarios')->insertGetId(array_merge([
            'id_empresas'=>1,'nombres'=>'Usuario QA','correo'=>null,
            'fin_suscripcion'=>$dias === null ? null : CarbonImmutable::today('America/Lima')->addDays($dias)->toDateString(),
        ], $extra));
    }

    public function test_limites_repeticiones_y_siguiente_dia_sin_correo(): void
    {
        foreach ([null,-1,0,1,2,3,4,5,6,7,8] as $dias) {
            $this->usuario($dias, ['estado'=>false]);
        }
        $this->artisan('usuarios:recordar-suscripcion --simular')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones', 0);
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones', 7);
        $this->assertSame(7, Notificacion::where('enviada',true)->where('leida',false)->count());
        Notificacion::first()->update(['leida'=>true]);
        $antes = DB::table('notificaciones')->get()->toJson();
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertSame($antes, DB::table('notificaciones')->get()->toJson());
        $this->assertSame(0, DB::table('usuarios')->where('estado',true)->count());
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-22 10:00', 'America/Lima'));
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones', 14);
        Mail::assertNothingSent();
    }

    public function test_datos_para_app_whatsapp_fecha_peru_y_renovacion(): void
    {
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-22 02:00:00', 'UTC'));
        $id = $this->usuario(1);
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $n = Notificacion::first();
        $this->assertSame(1, $n->datos['dias_restantes']);
        $this->assertSame('2026-09-22', $n->datos['fecha_fin']);
        $this->assertStringStartsWith('https://wa.me/51987654321?', $n->datos['url_renovacion']);
        $datos = (new NotificacionResource($n))->resolve();
        $this->assertStringEndsWith('/storage/email/notificaciones-fondo.webp', $datos['datos']['imagen_fondo_url']);
        $this->getJson('/api/notificaciones')->assertOk()->assertJsonPath('data.0.datos.dias_restantes',1);
        DB::table('usuarios')->where('id',$id)->update(['fin_suscripcion'=>'2026-10-30']);
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-22 10:00','America/Lima'));
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',1);
        $this->assertSame($n->datos, $n->fresh()->datos);
        Mail::assertNothingSent();
    }

    public function test_empresa_correcta_telefonos_y_sin_empresa(): void
    {
        foreach (['+51 912-345-678','0051912345678','invalido',null] as $telefono) {
            $empresa = DB::table('empresas')->insertGetId(['nombre'=>'Otra empresa','telefono'=>$telefono]);
            $id = $this->usuario(7,['id_empresas'=>$empresa]);
            $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
            $n = Notificacion::where('id_usuarios',$id)->firstOrFail();
            if ($telefono && $telefono !== 'invalido') {
                $this->assertStringStartsWith('https://wa.me/51912345678?', $n->datos['url_renovacion']);
            } else {
                $this->assertNull($n->datos['url_renovacion']);
            }
        }
        $id = $this->usuario(3,['id_empresas'=>null]);
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertNull(Notificacion::where('id_usuarios',$id)->firstOrFail()->datos['url_renovacion']);
        Mail::assertNothingSent();
    }

    public function test_fallo_de_guardado_revierte_y_permite_reintento(): void
    {
        $this->usuario(2);
        Notificacion::saved(function () { throw new \RuntimeException('QA'); });
        $this->artisan('usuarios:recordar-suscripcion')->assertFailed();
        $this->assertDatabaseCount('notificaciones',0);
        Notificacion::flushEventListeners();
        $this->artisan('usuarios:recordar-suscripcion')->assertSuccessful();
        $this->assertDatabaseCount('notificaciones',1);
        Mail::assertNothingSent();
    }

    public function test_migracion_conserva_notificaciones_existentes(): void
    {
        $migration = require database_path('migrations/2026_09_21_180000_add_datos_to_notificaciones.php');
        $migration->down();
        $id = DB::table('notificaciones')->insertGetId([
            'tipo'=>'sistema','titulo'=>'Aviso anterior','mensaje'=>'Conservar',
            'fecha_envio'=>'2026-09-20 10:00:00','leida'=>true,'enviada'=>true,
        ]);
        $antes = (array) DB::table('notificaciones')->find($id);
        $migration->up();
        $this->assertDatabaseHas('notificaciones',$antes);
        $this->getJson('/api/notificaciones')->assertOk()->assertJsonPath('data.0.datos',null);
        $migration->down();
        $this->assertSame($antes, (array) DB::table('notificaciones')->find($id));
    }
}
