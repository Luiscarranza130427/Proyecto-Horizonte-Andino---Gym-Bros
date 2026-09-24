<?php

namespace Tests\Feature;

use App\Models\EmpresaEjercicio;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EstadoEmpresaEjercicioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite', 'database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        foreach (['empresas','ejercicios'] as $name) {
            Schema::create($name, function (Blueprint $t) { $t->id(); $t->boolean('estado'); });
            DB::table($name)->insert([['id'=>1,'estado'=>true],['id'=>2,'estado'=>false]]);
        }
        (require database_path('migrations/2026_08_29_170121_create_empresa_ejercicio_table.php'))->up();
        EmpresaEjercicio::create(['id_empresas'=>2,'id_ejercicios'=>1,'estado'=>true]);
    }

    protected function tearDown(): void
    {
        EmpresaEjercicio::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_crea_actualiza_y_reintenta_sin_afectar_otra_empresa_o_estado_global(): void
    {
        $other = DB::table('empresa_ejercicio')->first();
        $global = DB::table('ejercicios')->get()->toJson();
        foreach ([0,0,1,false,true,'0','1'] as $estado) {
            $this->putJson('/api/empresas/1/ejercicios/1/estado', ['estado'=>$estado,'id_empresas'=>2])
                ->assertOk()->assertJsonPath('id_empresa',1)->assertJsonPath('id_ejercicio',1)
                ->assertJsonPath('estado',(bool) $estado);
            $this->assertDatabaseHas('empresa_ejercicio',['id_empresas'=>1,'id_ejercicios'=>1,'estado'=>(bool) $estado]);
            $this->assertDatabaseCount('empresa_ejercicio',2);
        }
        $this->assertEquals($other, DB::table('empresa_ejercicio')->where('id',$other->id)->first());
        $this->assertSame($global, DB::table('ejercicios')->get()->toJson());
        $this->putJson('/api/empresas/1/ejercicios/2/estado',['estado'=>1])->assertOk();
        $this->assertDatabaseHas('ejercicios',['id'=>2,'estado'=>false]);
    }

    public function test_invalidos_sin_accept_no_guardan(): void
    {
        foreach ([[],['estado'=>null],['estado'=>2],['estado'=>'activo'],['estado'=>[]]] as $body) {
            $this->put('/api/empresas/1/ejercicios/1/estado',$body)->assertUnprocessable()->assertJsonValidationErrors('estado');
        }
        $this->assertDatabaseCount('empresa_ejercicio',1);
    }

    public function test_empresa_o_ejercicio_inexistentes(): void
    {
        foreach (['/api/empresas/999/ejercicios/1/estado','/api/empresas/1/ejercicios/999/estado'] as $url) {
            $this->putJson($url,['estado'=>true])->assertNotFound()->assertJsonStructure(['message']);
        }
        $this->assertDatabaseCount('empresa_ejercicio',1);
    }

    public function test_fallo_revierte_sin_exponer_trazas(): void
    {
        EmpresaEjercicio::saved(function () { throw new \RuntimeException('Error privado QA'); });
        $this->put('/api/empresas/1/ejercicios/1/estado',['estado'=>true])->assertStatus(500)
            ->assertExactJson(['message'=>'No se pudo actualizar el estado del ejercicio para la empresa.']);
        $this->assertDatabaseCount('empresa_ejercicio',1);
    }
}
