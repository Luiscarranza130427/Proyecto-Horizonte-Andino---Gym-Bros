<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class DesactivarUsuariosFechaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        $this->travelTo(\Carbon\Carbon::parse('2026-09-17 12:00:00'));
        Schema::create('usuarios', function (Blueprint $t) {
            $t->id(); $t->boolean('estado'); $t->date('fin_suscripcion')->nullable(); $t->timestamps();
        });
        foreach ([[1,1,'2026-09-18'],[2,1,'2026-09-17'],[3,1,'2026-09-16'],[4,0,'2026-09-18'],[5,1,null]] as [$id,$estado,$fin]) {
            DB::table('usuarios')->insert(['id'=>$id,'estado'=>$estado,'fin_suscripcion'=>$fin]);
        }
    }

    protected function tearDown(): void
    {
        $this->travelBack();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_solo_desactiva_fechas_futuras_y_es_idempotente(): void
    {
        $before = DB::table('usuarios')->where('id','!=',1)->get()->toJson();
        $this->artisan('usuarios:desactivar-fecha-futura')->expectsOutputToContain('Usuarios desactivados: 1')->assertSuccessful();
        $this->assertDatabaseHas('usuarios',['id'=>1,'estado'=>0,'fin_suscripcion'=>'2026-09-18']);
        $this->assertSame($before, DB::table('usuarios')->where('id','!=',1)->get()->toJson());
        $all = DB::table('usuarios')->get()->toJson();
        $this->artisan('usuarios:desactivar-fecha-futura')->expectsOutputToContain('Usuarios desactivados: 0')->assertSuccessful();
        $this->assertSame($all, DB::table('usuarios')->get()->toJson());
    }

    public function test_simular_no_escribe_y_tabla_vacia_funciona(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        $this->artisan('usuarios:desactivar-fecha-futura --simular')->expectsOutputToContain('Usuarios que se desactivarian: 1')->assertSuccessful();
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
        DB::table('usuarios')->delete();
        $this->artisan('usuarios:desactivar-fecha-futura')->assertSuccessful();
    }
}
