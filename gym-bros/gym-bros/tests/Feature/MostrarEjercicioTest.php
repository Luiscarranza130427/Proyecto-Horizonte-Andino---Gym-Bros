<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MostrarEjercicioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('ejercicios', function (Blueprint $t) {
            $t->id(); $t->string('nombre'); $t->boolean('estado');
        });
        DB::table('ejercicios')->insert([['id'=>1,'nombre'=>'Press banca','estado'=>true],
            ['id'=>2,'nombre'=>'Remo','estado'=>false]]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_consulta_individual_incluye_inactivos_sin_modificar_datos(): void
    {
        $before = DB::table('ejercicios')->get()->toJson();
        foreach ([1=>'Press banca',2=>'Remo'] as $id=>$nombre) {
            $this->get('/api/ejercicios/'.$id)->assertOk()->assertJsonPath('data.id',$id)
                ->assertJsonPath('data.nombre',$nombre)->assertJsonStructure(['data'=>[
                    'descripcion','tipo','instrucciones','nivel','equipamiento','estado',
                    'enlace_video','imagen_ejercicio','id_grupos_musculares']]);
        }
        $this->assertSame($before, DB::table('ejercicios')->get()->toJson());
        $this->getJson('/api/ejercicios')->assertOk()->assertJsonCount(2,'data');
    }

    public function test_inexistente_devuelve_json_sin_accept(): void
    {
        $this->get('/api/ejercicios/999')->assertNotFound()
            ->assertExactJson(['message'=>'Ejercicio no encontrado.']);
    }
}
