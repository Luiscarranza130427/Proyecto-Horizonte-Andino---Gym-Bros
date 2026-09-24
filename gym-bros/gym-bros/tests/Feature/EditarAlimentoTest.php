<?php

namespace Tests\Feature;

use App\Models\Alimento;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Tests\TestCase;

class EditarAlimentoTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:', 'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:',DB::connection()->getDatabaseName());
        (require database_path('migrations/2026_08_21_224403_create_alimentos.php'))->up();
        Schema::table('alimentos',fn (Blueprint $t)=>$t->boolean('activo')->default(true));
        Schema::table('alimentos', function (Blueprint $t) {
            foreach (['base_unidad','estado_preparacion','fuente_nutricional','grupo_menu','tipos_comida'] as $campo) {
                $t->text($campo)->nullable();
            }
            foreach (['gramos_por_unidad','densidad_g_ml','porcion_min','porcion_max','paso_porcion'] as $campo) {
                $t->decimal($campo, 12, 4)->nullable();
            }
            $t->boolean('nutricion_verificada')->default(false);
            $t->boolean('restricciones_verificadas')->default(false);
        });
        foreach ([1,2] as $id) {
            Alimento::create(['id'=>$id,'nombre'=>'Alimento QA','tipo'=>'fruta','calorias'=>50,
                'proteinas'=>1,'carbohidratos'=>10,'grasas'=>0,'fibra'=>2]);
        }
    }
    protected function tearDown(): void
    {
        Alimento::flushEventListeners(); DB::disconnect('sqlite'); parent::tearDown();
    }
    public function test_edita_parcial_solo_alimento_indicado(): void
    {
        $otro=DB::table('alimentos')->find(2);
        $this->putJson('/api/alimentos/1',['nombre'=>'Nuevo','calorias'=>60.25,'activo'=>0,'id'=>2])
            ->assertOk()->assertJsonPath('data.nombre','Nuevo');
        $this->assertDatabaseHas('alimentos',['id'=>1,'calorias'=>60.25,'tipo'=>'fruta','activo'=>0]);
        $this->assertEquals($otro,DB::table('alimentos')->find(2));
    }
    public function test_invalidos_json_y_no_escritura(): void
    {
        $antes=DB::table('alimentos')->get()->toJson();
        foreach ([['nombre'=>null],['calorias'=>-1],['grasas'=>10000],['proteinas'=>1.234],['tipo'=>'invalido'],['activo'=>2],[]] as $datos) {
            $this->put('/api/alimentos/1',$datos)->assertUnprocessable()->assertJsonStructure(['message','errors']);
        }
        $this->assertSame($antes,DB::table('alimentos')->get()->toJson());
        $this->put('/api/alimentos/999',['nombre'=>'Nuevo'])->assertNotFound();
    }
    public function test_fallo_revierte(): void
    {
        Alimento::saved(function () {throw new \RuntimeException('QA');});
        $this->put('/api/alimentos/1',['nombre'=>'Nuevo'])->assertStatus(500)
            ->assertExactJson(['message'=>'No se pudo actualizar el alimento.']);
        $this->assertDatabaseHas('alimentos',['id'=>1,'nombre'=>'Alimento QA']);
    }

    public function test_elimina_solo_alimento_sin_relaciones(): void
    {
        foreach (['comida_alimentos','preferencias_alimentarias'] as $tabla) {
            Schema::create($tabla, function (Blueprint $t) {
                $t->id();
                $t->foreignId('id_alimentos')->constrained('alimentos')->cascadeOnDelete();
            });
        }
        foreach (['comida_alimentos','preferencias_alimentarias'] as $tabla) {
            DB::table($tabla)->insert(['id_alimentos'=>1]);
            $this->deleteJson('/api/alimentos/1')->assertStatus(409)->assertJsonStructure(['message']);
            $this->assertDatabaseHas($tabla,['id_alimentos'=>1]);
            DB::table($tabla)->delete();
        }
        $this->deleteJson('/api/alimentos/1')->assertOk()->assertJsonPath('message','Alimento eliminado correctamente.');
        $this->assertDatabaseMissing('alimentos',['id'=>1]);
        $this->assertDatabaseHas('alimentos',['id'=>2]);
        $this->deleteJson('/api/alimentos/1')->assertNotFound();
        Alimento::deleted(function () {throw new \RuntimeException('QA');});
        $this->deleteJson('/api/alimentos/2')->assertStatus(500);
        $this->assertDatabaseHas('alimentos',['id'=>2]);
    }

    public function test_edita_configuracion_completa_y_valida_parciales(): void
    {
        $datos = ['nombre'=>'Fruta QA','tipo'=>'fruta','activo'=>true,
            'calorias'=>50,'proteinas'=>1,'carbohidratos'=>10,'grasas'=>0,'fibra'=>2,
            'base_unidad'=>'gramos','estado_preparacion'=>'crudo','gramos_por_unidad'=>100,
            'densidad_g_ml'=>null,'fuente_nutricional'=>'Fixture QA','nutricion_verificada'=>true,
            'restricciones_verificadas'=>false,'grupo_menu'=>'fruta','tipos_comida'=>['desayuno'],
            'porcion_min'=>50,'porcion_max'=>200,'paso_porcion'=>10];
        $this->putJson('/api/alimentos/1',$datos)->assertOk()
            ->assertJsonPath('data.base_unidad','gramos')->assertJsonPath('data.tipos_comida',['desayuno']);
        $this->assertDatabaseHas('alimentos',['id'=>1,'porcion_max'=>200,'gramos_por_unidad'=>100]);
        $this->putJson('/api/alimentos/1',['porcion_max'=>100])->assertOk();
        foreach ([['porcion_max'=>40],['paso_porcion'=>200],['fibra'=>20],
            ['tipos_comida'=>['cena','cena']],['base_unidad'=>'litros']] as $invalido) {
            $this->putJson('/api/alimentos/1',$invalido)->assertUnprocessable()->assertJsonStructure(['message','errors']);
        }
        $this->putJson('/api/alimentos/1',['gramos_por_unidad'=>null])->assertOk()->assertJsonPath('data.gramos_por_unidad',null);
        $this->getJson('/api/alimentos')->assertOk()->assertJsonPath('data.0.base_unidad','gramos');
        $this->assertDatabaseHas('alimentos',['id'=>1,'porcion_max'=>100,'fibra'=>2]);
    }
}
