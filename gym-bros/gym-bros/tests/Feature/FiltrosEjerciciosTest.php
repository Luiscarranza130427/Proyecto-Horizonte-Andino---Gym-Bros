<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class FiltrosEjerciciosTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', fn (Blueprint $t) => $t->id());
        Schema::create('grupos_musculares', function (Blueprint $t) { $t->id(); $t->string('descripcion'); });
        Schema::create('ejercicios', function (Blueprint $t) {
            $t->id(); $t->string('nombre'); $t->string('descripcion')->nullable();
            $t->string('tipo'); $t->string('nivel'); $t->string('equipamiento');
            $t->boolean('estado'); $t->unsignedBigInteger('id_grupos_musculares')->nullable();
        });
        Schema::create('ejercicios_grupo_muscular', function (Blueprint $t) {
            $t->unsignedBigInteger('id_ejercicios'); $t->unsignedBigInteger('id_grupos_musculares');
        });
        (require database_path('migrations/2026_08_29_170121_create_empresa_ejercicio_table.php'))->up();
        DB::table('empresas')->insert([['id'=>1],['id'=>2]]);
        DB::table('grupos_musculares')->insert([['id'=>1,'descripcion'=>'Pecho'],['id'=>2,'descripcion'=>'Espalda']]);
        foreach ([[1,'Press banca','fuerza','Principiante','barra y banco',1,1],
            [2,'Remo','fuerza','Intermedio','mancuernas',0,2],
            [3,'Carrera','cardio','Principiante','cinta',1,null],
            [4,'Press avanzado','fuerza','Avanzado','barra',1,1]] as [$id,$name,$type,$level,$equipment,$state,$group]) {
            DB::table('ejercicios')->insert(['id'=>$id,'nombre'=>$name,'descripcion'=>'Descripcion '.$name,
                'tipo'=>$type,'nivel'=>$level,'equipamiento'=>$equipment,'estado'=>$state,'id_grupos_musculares'=>$group]);
        }
        DB::table('ejercicios_grupo_muscular')->insert(['id_ejercicios'=>4,'id_grupos_musculares'=>2]);
        DB::table('empresa_ejercicio')->insert([
            ['id_empresas'=>1,'id_ejercicios'=>1,'estado'=>0],
            ['id_empresas'=>1,'id_ejercicios'=>2,'estado'=>1],
            ['id_empresas'=>2,'id_ejercicios'=>1,'estado'=>1],
        ]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_filtros_individuales_y_combinados(): void
    {
        foreach (['search=press'=>[1,4], 'category=fuerza'=>[1,2,4], 'level=principiante'=>[1,3],
            'equipment=barra'=>[1,4], 'category=Pecho'=>[1,4], 'category=2'=>[2,4],
            'search=press&category=fuerza&level=principiante&equipment=barra'=>[1],
            'search=inexistente'=>[], 'search=%25'=>[]] as $query=>$ids) {
            $r=$this->getJson('/api/ejercicios?'.$query)->assertOk();
            $this->assertSame($ids,array_column($r->json('data'),'id'));
        }
    }

    public function test_estado_empresa_independiente_incluye_no_configurados_como_inactivos(): void
    {
        foreach (['id_empresas=1&status=active'=>[2], 'id_empresas=1&status=0'=>[1,3,4],
            'id_empresas=2&status=true'=>[1], 'status=activo'=>[1,3,4],
            'id_empresas=1&status=inactive&search=Press'=>[1,4]] as $query=>$ids) {
            $r=$this->getJson('/api/ejercicios?'.$query)->assertOk();
            $this->assertSame($ids,array_column($r->json('data'),'id'));
        }
    }

    public function test_paginacion_filtrada_vacios_y_compatibilidad(): void
    {
        $this->getJson('/api/ejercicios?search=&category=&level=&equipment=&status=&page=1&per_page=2')
            ->assertOk()->assertJsonCount(2,'data')->assertJsonPath('meta.total',4);
        $r=$this->getJson('/api/ejercicios?category=fuerza&page=2&per_page=2')->assertOk()
            ->assertJsonPath('meta.total',3)->assertJsonPath('meta.current_page',2);
        $this->assertSame([4],array_column($r->json('data'),'id'));
        $this->getJson('/api/ejercicios')->assertOk()->assertJsonCount(4,'data')->assertJsonMissingPath('meta');
    }

    public function test_entradas_invalidas_json_422(): void
    {
        foreach (['page=0'=>'page','per_page=101'=>'per_page','level[]=a'=>'level',
            'status=desconocido'=>'status','level=experto'=>'level','id_empresas[]=1'=>'id_empresas'] as $query=>$field) {
            $this->get('/api/ejercicios?'.$query)->assertUnprocessable()->assertJsonValidationErrors($field);
        }
        $this->assertDatabaseCount('ejercicios',4);
        $this->assertDatabaseCount('empresa_ejercicio',3);
    }
}
