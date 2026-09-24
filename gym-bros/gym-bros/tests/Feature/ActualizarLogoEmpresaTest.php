<?php

namespace Tests\Feature;

use App\Models\Empresa;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ActualizarLogoEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Storage::fake('public');
        Schema::create('empresas', function (Blueprint $table) {
            $table->id();
            $table->string('logo');
            $table->string('nombre');
            $table->string('banner_1')->nullable();
            $table->timestamps();
        });
        DB::table('empresas')->insert([
            ['id' => 1, 'logo' => 'empresas/anterior.webp', 'nombre' => 'Gym 1', 'banner_1' => 'empresas/anterior.webp'],
            ['id' => 2, 'logo' => 'empresas/anterior.webp', 'nombre' => 'Gym 2', 'banner_1' => null],
        ]);
        Storage::disk('public')->put('empresas/anterior.webp', 'historico compartido');
    }

    protected function tearDown(): void
    {
        Empresa::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_almacena_archivos_y_solo_modifica_logo_con_nombre_generado(): void
    {
        foreach (['jpg', 'jpeg', 'png', 'webp'] as $extension) {
            $response = $this->post('/api/empresas/1/logo', [
                'logo' => UploadedFile::fake()->image('logo.'.$extension, 120, 80),
                'nombre' => 'No cambiar', 'id' => 2, 'banner_1' => 'No cambiar',
            ])->assertOk()->assertJsonPath('id_empresa', 1);
            $path = $response->json('logo');
            $this->assertStringStartsWith('empresas/', $path);
            $this->assertNotSame('empresas/logo.'.$extension, $path);
            Storage::disk('public')->assertExists($path);
            $this->assertSame('http://localhost/storage/'.$path, $response->json('logo_url'));
            $this->assertDatabaseHas('empresas', ['id' => 1, 'logo' => $path, 'nombre' => 'Gym 1', 'banner_1' => 'empresas/anterior.webp']);
        }
        Storage::disk('public')->assertExists('empresas/anterior.webp');
        $this->assertDatabaseHas('empresas', ['id' => 2, 'logo' => 'empresas/anterior.webp']);
    }

    public function test_rechaza_ausencia_texto_archivo_falso_formatos_y_peso_excesivo(): void
    {
        $before = DB::table('empresas')->get()->toJson();
        foreach ([null, 'empresas/logo.png', UploadedFile::fake()->create('falso.jpg', 20, 'text/plain'),
            UploadedFile::fake()->create('vector.svg', 20, 'image/svg+xml'),
            UploadedFile::fake()->image('logo.gif'), UploadedFile::fake()->image('grande.png')->size(5121)] as $logo) {
            $this->post('/api/empresas/1/logo', ['logo' => $logo])->assertUnprocessable()->assertJsonValidationErrors('logo');
        }
        $this->assertSame($before, DB::table('empresas')->get()->toJson());
        $this->assertCount(1, Storage::disk('public')->allFiles());
    }

    public function test_empresa_inexistente_no_almacena_y_limite_de_cinco_mb_aceptado(): void
    {
        $this->post('/api/empresas/999/logo', ['logo' => UploadedFile::fake()->image('logo.png')])
            ->assertNotFound()->assertJsonStructure(['message']);
        $this->assertCount(1, Storage::disk('public')->allFiles());
        $this->post('/api/empresas/1/logo', ['logo' => UploadedFile::fake()->image('logo.png')->size(5120)])->assertOk();
    }

    public function test_url_publica_utiliza_host_de_la_peticion_no_localhost_configurado(): void
    {
        config(['app.url' => 'http://localhost']);
        $res = $this->post('http://192.168.1.70:8000/api/empresas/1/logo', [
            'logo' => UploadedFile::fake()->image('logo.png'),
        ])->assertOk();
        $this->assertSame('http://192.168.1.70:8000/storage/'.$res->json('logo'), $res->json('logo_url'));
    }

    public function test_error_base_de_datos_revierte_y_limpia_solo_archivo_nuevo_sin_trazas(): void
    {
        config(['app.debug' => true]);
        Empresa::updated(function () { throw new \RuntimeException('QA no mostrar datos SQL'); });
        $this->post('/api/empresas/1/logo', ['logo' => UploadedFile::fake()->image('logo.png')])
            ->assertStatus(500)->assertExactJson(['message' => 'No se pudo actualizar el logo de la empresa.']);
        $this->assertDatabaseHas('empresas', ['id' => 1, 'logo' => 'empresas/anterior.webp']);
        $this->assertSame(['empresas/anterior.webp'], Storage::disk('public')->allFiles());
    }
}
