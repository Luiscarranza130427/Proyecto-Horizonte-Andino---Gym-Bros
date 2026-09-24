<?php

namespace Tests\Feature;

use App\Models\Usuario;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ActualizarFotoUsuarioTest extends TestCase
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
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('foto_perfil')->nullable();
            $table->timestamps();
        });
        DB::table('usuarios')->insert([
            ['id' => 1, 'foto_perfil' => null, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'foto_perfil' => 'usuario/anterior.webp', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    protected function tearDown(): void
    {
        Usuario::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_stores_image_updates_only_profile_path_and_returns_public_url(): void
    {
        $before = DB::table('usuarios')->where('id', 1)->first();
        $response = $this->postJson('/api/usuarios/1/foto-perfil', [
            'foto_perfil' => UploadedFile::fake()->image('perfil.png', 120, 120),
        ])->assertOk()->assertJsonPath('id_usuario', 1)
            ->assertJsonPath('message', 'Imagen de perfil actualizada correctamente');

        $path = $response->json('foto_perfil');
        $this->assertStringStartsWith('usuario/', $path);
        $this->assertStringEndsWith('.png', $path);
        $this->assertSame('http://localhost/storage/'.$path, $response->json('foto_url'));
        Storage::disk('public')->assertExists($path);
        $after = DB::table('usuarios')->where('id', 1)->first();
        $this->assertSame($before->id, $after->id);
        $this->assertSame($before->foto_perfil, null);
        $this->assertSame($path, $after->foto_perfil);
    }

    public function test_replaces_profile_path_but_preserves_previous_files_like_company_logo(): void
    {
        Storage::disk('public')->put('usuario/anterior.webp', 'old');
        Storage::disk('public')->put('usuario/no-eliminar.webp', 'keep');
        $response = $this->postJson('/api/usuarios/2/foto-perfil', [
            'foto_perfil' => UploadedFile::fake()->image('nuevo.webp', 80, 80),
        ])->assertOk();
        $path = $response->json('foto_perfil');
        Storage::disk('public')->assertExists('usuario/anterior.webp');
        Storage::disk('public')->assertExists($path);
        Storage::disk('public')->assertExists('usuario/no-eliminar.webp');
    }

    public function test_rejects_non_images_invalid_extensions_and_oversized_files_without_writes(): void
    {
        foreach ([
            UploadedFile::fake()->create('document.pdf', 100, 'application/pdf'),
            UploadedFile::fake()->create('script.php', 100, 'text/plain'),
            UploadedFile::fake()->image('large.jpg')->size(5121),
        ] as $file) {
            $before = DB::table('usuarios')->where('id', 1)->first();
            $this->postJson('/api/usuarios/1/foto-perfil', ['foto_perfil' => $file])
                ->assertUnprocessable()->assertJsonValidationErrors('foto_perfil');
            $this->assertEquals($before, DB::table('usuarios')->where('id', 1)->first());
        }
        Storage::disk('public')->assertDirectoryEmpty('usuario');
    }

    public function test_requires_file_and_rejects_unknown_or_invalid_users(): void
    {
        $this->postJson('/api/usuarios/1/foto-perfil')->assertUnprocessable()->assertJsonValidationErrors('foto_perfil');
        foreach (['999', '0', '-1', 'abc', '1.5'] as $id) {
            $this->postJson('/api/usuarios/'.$id.'/foto-perfil', [
                'foto_perfil' => UploadedFile::fake()->image('perfil.jpg'),
            ])->assertNotFound();
        }
        Storage::disk('public')->assertDirectoryEmpty('usuario');
    }

    public function test_previous_path_outside_public_disk_is_never_deleted(): void
    {
        DB::table('usuarios')->where('id', 2)->update(['foto_perfil' => '../empresas/logo.webp']);
        Storage::disk('public')->put('empresas/logo.webp', 'keep');
        $response = $this->postJson('/api/usuarios/2/foto-perfil', [
            'foto_perfil' => UploadedFile::fake()->image('nuevo.jpg'),
        ])->assertOk();
        Storage::disk('public')->assertExists('empresas/logo.webp');
        Storage::disk('public')->assertExists($response->json('foto_perfil'));
    }

    public function test_public_url_uses_request_host_and_upload_accepts_supported_formats(): void
    {
        config(['filesystems.disks.public.url' => 'http://localhost/storage']);
        $other = DB::table('usuarios')->where('id', 2)->first();
        foreach (['jpg', 'jpeg', 'png', 'webp'] as $extension) {
            $response = $this->post('http://192.168.1.70:8000/api/usuarios/1/foto-perfil', [
                'foto_perfil' => UploadedFile::fake()->image('foto.'.$extension)->size(5120),
                'id' => 2,
            ])->assertOk()->assertJsonPath('id_usuario', 1);
            $path = $response->json('foto_perfil');
            $this->assertSame('http://192.168.1.70:8000/storage/'.$path, $response->json('foto_url'));
            Storage::disk('public')->assertExists($path);
            $this->assertDatabaseHas('usuarios', ['id' => 1, 'foto_perfil' => $path]);
        }
        $this->assertEquals($other, DB::table('usuarios')->where('id', 2)->first());
    }

    public function test_validation_returns_json_without_accept_and_preserves_database(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        foreach ([null, 'usuario/foto.png', UploadedFile::fake()->create('falso.jpg', 1, 'text/plain'),
            UploadedFile::fake()->image('foto.gif'), UploadedFile::fake()->create('foto.svg', 1, 'image/svg+xml')] as $file) {
            $this->post('/api/usuarios/1/foto-perfil', ['foto_perfil' => $file])
                ->assertUnprocessable()->assertJsonValidationErrors('foto_perfil');
        }
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_save_failure_returns_json_and_rolls_back_file_and_database(): void
    {
        Storage::disk('public')->put('usuario/anterior.webp', 'keep');
        $before = DB::table('usuarios')->get()->toJson();
        Usuario::saved(function () { throw new \RuntimeException('Error privado QA'); });
        $this->post('/api/usuarios/2/foto-perfil', ['foto_perfil' => UploadedFile::fake()->image('foto.png')])
            ->assertStatus(500)->assertExactJson(['message' => 'No se pudo actualizar la imagen de perfil.']);
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
        $this->assertSame(['usuario/anterior.webp'], Storage::disk('public')->allFiles());
    }

    public function test_cancelled_save_is_not_reported_as_success(): void
    {
        Usuario::saving(fn () => false);
        $this->post('/api/usuarios/1/foto-perfil', ['foto_perfil' => UploadedFile::fake()->image('foto.png')])
            ->assertStatus(500)->assertExactJson(['message' => 'No se pudo actualizar la imagen de perfil.']);
        $this->assertDatabaseHas('usuarios', ['id' => 1, 'foto_perfil' => null]);
        $this->assertSame([], Storage::disk('public')->allFiles());
    }
}
