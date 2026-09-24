<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\UploadedFile;
use App\Models\Banner;
use Tests\TestCase;

class BannerCrudTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        Storage::fake('public');
        (require database_path('migrations/2026_08_21_224547_create_banners.php'))->up();
    }

    public function test_crear_editar_y_eliminar(): void
    {
        $datos = ['imagen'=>UploadedFile::fake()->image('banner.png'),'contenido_text'=>'Anterior',
            'texto_boton'=>'Ver','enlace_boton'=>'https://example.com'];
        $this->postJson('/api/banners',$datos)->assertCreated();
        $id = DB::table('banners')->value('id');
        $datos['imagen'] = DB::table('banners')->value('imagen');
        $this->assertStringStartsWith('banners-web/', $datos['imagen']);
        Storage::disk('public')->assertExists($datos['imagen']);
        $this->assertDatabaseHas('banners',$datos);
        $this->putJson('/api/banners/'.$id,['contenido_text'=>null])->assertOk();
        $this->assertDatabaseHas('banners',array_merge($datos,['contenido_text'=>null]));
        $this->putJson('/api/banners/'.$id,['texto_boton'=>'Nuevo','id'=>999])->assertOk();
        $this->assertDatabaseHas('banners',['id'=>$id,'texto_boton'=>'Nuevo']);
        $this->post('/api/banners/'.$id, ['_method'=>'PUT','imagen'=>UploadedFile::fake()->image('nuevo.jpg')],
            ['Accept'=>'application/json'])->assertOk();
        $nuevaRuta = DB::table('banners')->value('imagen');
        $this->assertNotSame($datos['imagen'], $nuevaRuta);
        Storage::disk('public')->assertExists($nuevaRuta);
        $this->deleteJson('/api/banners/'.$id)->assertOk();
        $this->assertDatabaseCount('banners',0);
        $this->deleteJson('/api/banners/'.$id)->assertNotFound();
        $this->putJson('/api/banners/'.$id,['texto_boton'=>'Ver'])->assertNotFound();
    }

    public function test_validaciones_no_modifican_datos(): void
    {
        $this->postJson('/api/banners',[])->assertUnprocessable()
            ->assertJsonValidationErrors(['imagen','texto_boton','enlace_boton']);
        $this->postJson('/api/banners',['imagen'=>str_repeat('a',251),'texto_boton'=>str_repeat('a',21),
            'enlace_boton'=>str_repeat('a',301),'contenido_text'=>str_repeat('a',101)])
            ->assertUnprocessable()->assertJsonValidationErrors(['imagen','texto_boton','enlace_boton','contenido_text']);
        $this->putJson('/api/banners/1',[])->assertUnprocessable();
        $this->putJson('/api/banners/1',['imagen'=>null])->assertUnprocessable()->assertJsonValidationErrors('imagen');
        $this->assertDatabaseCount('banners',0);
    }

    public function test_rechaza_archivos_invalidos_y_demasiado_grandes(): void
    {
        foreach ([UploadedFile::fake()->create('archivo.txt', 1, 'text/plain'),
            UploadedFile::fake()->image('grande.png')->size(5121)] as $archivo) {
            $this->post('/api/banners',['imagen'=>$archivo,'texto_boton'=>'Ver','enlace_boton'=>'https://example.com'],
                ['Accept'=>'application/json'])->assertUnprocessable()->assertJsonValidationErrors('imagen');
        }
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_limpia_archivo_nuevo_si_falla_guardado(): void
    {
        Banner::saving(fn () => false);
        try {
            $this->post('/api/banners',['imagen'=>UploadedFile::fake()->image('banner.png'),
                'texto_boton'=>'Ver','enlace_boton'=>'https://example.com'],['Accept'=>'application/json'])->assertStatus(500);
            $this->assertDatabaseCount('banners',0);
            $this->assertSame([], Storage::disk('public')->allFiles());
        } finally { Banner::flushEventListeners(); }
    }
}
