<?php

namespace Tests\Feature;

use App\Models\Ejercicio;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CrearEjercicioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Storage::fake('public');
        Schema::create('grupos_musculares', function (Blueprint $t) {
            $t->id(); $t->string('tipo')->default('pecho');
            $t->text('descripcion')->nullable(); $t->boolean('estado')->default(true);
        });
        Schema::create('empresas', fn (Blueprint $t) => $t->id());
        DB::table('grupos_musculares')->insert(['id'=>1]);
        (require database_path('migrations/2026_08_21_224303_create_ejercicios.php'))->up();
        (require database_path('migrations/2026_08_29_170121_create_empresa_ejercicio_table.php'))->up();
    }

    protected function tearDown(): void
    {
        Ejercicio::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function payload(): array
    {
        return ['nombre'=>'Press QA','descripcion'=>'Descripcion','tipo'=>'fuerza',
            'instrucciones'=>'Instrucciones QA','nivel'=>'Principiante','equipamiento'=>'barra',
            'imagen_ejercicio'=>UploadedFile::fake()->image('ejercicio.png'),'id_grupos_musculares'=>1];
    }

    public function test_crea_inactivo_con_grupo_y_no_activa_empresas(): void
    {
        $r=$this->postJson('/api/ejercicios',$this->payload()+['id_empresas'=>1,'id'=>99])->assertCreated()
            ->assertJsonPath('data.nombre','Press QA')->assertJsonPath('data.nivel','principiante')
            ->assertJsonPath('data.tipo_grupo_muscular','pecho')->assertJsonPath('data.tipo','fuerza');
        $this->assertDatabaseHas('ejercicios',['id'=>$r->json('data.id'),'estado'=>0,'id_grupos_musculares'=>1]);
        $this->assertDatabaseCount('empresa_ejercicio',0);
        $this->getJson('/api/ejercicios/'.$r->json('data.id'))->assertOk();
    }

    public function test_subida_imagen_y_estado_explicito(): void
    {
        foreach (['jpg','jpeg','png','webp'] as $ext) {
            $r=$this->post('/api/ejercicios',array_replace($this->payload(),[
                'imagen_ejercicio'=>UploadedFile::fake()->image('foto.'.$ext),'estado'=>1]))->assertCreated();
            $path=$r->json('data.imagen_ejercicio');
            $this->assertStringStartsWith('ejercicios/',$path);
            Storage::disk('public')->assertExists($path);
            $this->assertSame('http://localhost/storage/'.$path, $r->json('data.imagen_url'));
            $this->assertDatabaseHas('ejercicios',['id'=>$r->json('data.id'),'estado'=>1,'imagen_ejercicio'=>$path]);
        }
    }

    public function test_invalidos_json_sin_escrituras(): void
    {
        foreach ([['id_grupos_musculares'=>null],['id_grupos_musculares'=>999],['nivel'=>'experto'],
            ['tipo'=>'otro'],['nombre'=>str_repeat('a',101)],['estado'=>2],['imagen_ejercicio'=>null],
            ['imagen_ejercicio'=>'ejercicios/imagen.webp'],
            ['imagen_ejercicio'=>UploadedFile::fake()->create('falso.jpg',1,'text/plain')],
            ['imagen_ejercicio'=>UploadedFile::fake()->image('grande.png')->size(5121)]] as $change) {
            $this->post('/api/ejercicios',array_replace($this->payload(),$change))
                ->assertUnprocessable()->assertJsonValidationErrors(array_keys($change));
        }
        $this->post('/api/ejercicios',[])->assertUnprocessable();
        $this->assertDatabaseCount('ejercicios',0);
        $this->assertSame([],Storage::disk('public')->allFiles());
    }

    public function test_fallo_revierte_fila_y_archivo(): void
    {
        Ejercicio::saved(function () { throw new \RuntimeException('Fallo privado QA'); });
        $this->post('/api/ejercicios',array_replace($this->payload(),[
            'imagen_ejercicio'=>UploadedFile::fake()->image('foto.png')]))->assertStatus(500)
            ->assertExactJson(['message'=>'No se pudo crear el ejercicio.']);
        $this->assertDatabaseCount('ejercicios',0);
        $this->assertSame([],Storage::disk('public')->allFiles());
    }

    public function test_selector_devuelve_solo_id_y_tipo_sin_descripcion(): void
    {
        DB::table('grupos_musculares')->insert(['id'=>2,'tipo'=>'espalda','descripcion'=>'No enviar','estado'=>false]);
        $this->get('/api/gruposmusculares/tipos')->assertOk()->assertExactJson([
            'data'=>[['id'=>1,'tipo'=>'pecho'],['id'=>2,'tipo'=>'espalda']],
        ]);
        DB::table('grupos_musculares')->delete();
        $this->getJson('/api/gruposmusculares/tipos')->assertOk()->assertExactJson(['data'=>[]]);
    }
}
