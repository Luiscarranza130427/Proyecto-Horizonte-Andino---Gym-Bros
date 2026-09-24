<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class EditarUsuarioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $t) { $t->id(); });
        DB::table('empresas')->insert(['id' => 1]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        foreach ([1, 2] as $id) {
            DB::table('usuarios')->insert(['id' => $id, 'nombres' => 'Nombre', 'apellidos' => 'Apellido',
                'apodo' => 'Apodo', 'genero' => 'Varon', 'correo' => "usuario$id@example.invalid",
                'password_hash' => 'hash-no-modificar', 'tipo_documento' => 'DNI', 'numero_documento' => '00123456',
                'telefono' => '999999999', 'direccion' => 'Anterior', 'fecha_registro' => '2026-01-01',
                'fecha_nacimiento' => '2000-01-01', 'tipo_usuario' => 'Usuario', 'estado' => true, 'id_empresas' => 1]);
        }
    }

    protected function tearDown(): void
    {
        Usuario::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_actualiza_todos_los_campos_reportados_sin_cambiar_otro_usuario(): void
    {
        $other = DB::table('usuarios')->find(2);
        $data = ['correo' => 'nuevo@example.invalid', 'telefono' => '012345678901',
            'tipo_documento' => 'PASAPORTE', 'numero_documento' => '001234AB',
            'genero' => 'Mujer', 'direccion' => str_repeat('a', 255)];
        $response = $this->putJson('/api/usuarios/1', $data)->assertOk()->assertJsonPath('id_usuario', 1)
            ->assertJsonPath('nombre', 'Nombre')->assertJsonMissingPath('password_hash');
        foreach ($data as $key => $value) { $response->assertJsonPath($key, $value); }
        $this->assertDatabaseHas('usuarios', ['id' => 1] + $data);
        $this->assertEquals($other, DB::table('usuarios')->find(2));
    }

    public function test_edicion_parcial_conserva_omitidos_y_correo_propio(): void
    {
        $before = (array) DB::table('usuarios')->find(1);
        $this->putJson('/api/usuarios/1', ['telefono' => '123456789'])->assertOk();
        $after = (array) DB::table('usuarios')->find(1);
        unset($before['telefono'], $after['telefono'], $before['updated_at'], $after['updated_at']);
        $this->assertSame($before, $after);
        $this->putJson('/api/usuarios/1', ['correo' => 'usuario1@example.invalid'])->assertOk();
        $this->putJson('/api/usuarios/1', ['direccion' => null])->assertOk()->assertJsonPath('direccion', null);
        foreach (['DNI', 'PASAPORTE', 'OTRO'] as $tipo) {
            $this->putJson('/api/usuarios/1', ['tipo_documento' => $tipo])->assertOk()->assertJsonPath('tipo_documento', $tipo);
        }
        $this->putJson('/api/usuarios/1', ['nombres' => 'Nuevo', 'apellidos' => 'Apellido2', 'apodo' => 'Nuevo apodo'])
            ->assertOk()->assertJsonPath('nombre', 'Nuevo')->assertJsonPath('apodo', 'Nuevo apodo');
    }

    public function test_cambiar_solo_correo_persiste_y_conserva_todos_los_demas_campos(): void
    {
        $before = (array) DB::table('usuarios')->find(1);
        $this->putJson('/api/usuarios/1', ['correo' => 'solo-correo@example.invalid'])
            ->assertOk()->assertJsonPath('correo', 'solo-correo@example.invalid');
        $after = (array) DB::table('usuarios')->find(1);
        $this->assertSame('solo-correo@example.invalid', $after['correo']);
        unset($before['correo'], $after['correo'], $before['updated_at'], $after['updated_at']);
        $this->assertSame($before, $after);
    }

    public function test_invalidos_devuelven_json_422_sin_cambios(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        foreach ([['correo' => 'invalido'], ['correo' => 'usuario2@example.invalid'], ['telefono' => str_repeat('1', 13)],
            ['numero_documento' => 123], ['numero_documento' => str_repeat('1', 13)], ['genero' => 'Masculino'],
            ['tipo_documento' => 'CE'], ['direccion' => str_repeat('a', 256)], ['nombres' => null],
            ['genero' => null], ['telefono' => null], ['correo' => null], ['tipo_documento' => null]] as $data) {
            $this->put('/api/usuarios/1', $data)->assertUnprocessable()->assertJsonValidationErrors(array_keys($data));
        }
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
    }

    public function test_no_permite_cambios_sensibles_y_rechaza_peticion_sin_campos_editables(): void
    {
        foreach ([[], ['email' => 'no@example.invalid'], ['tipo_usuario' => 'Administrador']] as $data) {
            $this->put('/api/usuarios/1', $data)->assertUnprocessable()->assertJsonValidationErrors('datos');
        }
        $this->putJson('/api/usuarios/1', ['telefono' => '123', 'id' => 2, 'id_empresas' => 99,
            'tipo_usuario' => 'Administrador', 'estado' => false, 'password_hash' => 'nuevo-password'])
            ->assertOk();
        $this->assertDatabaseHas('usuarios', ['id' => 1, 'tipo_usuario' => 'Usuario', 'estado' => true,
            'id_empresas' => 1, 'password_hash' => 'hash-no-modificar']);
        $this->put('/api/usuarios/999', ['telefono' => '123'])->assertNotFound();
    }

    public function test_fallo_de_guardado_revierte_y_no_expone_trazas(): void
    {
        $before = DB::table('usuarios')->get()->toJson();
        Usuario::saved(function () { throw new \RuntimeException('Error privado QA'); });
        $this->put('/api/usuarios/1', ['telefono' => '123'])->assertStatus(500)
            ->assertExactJson(['message' => 'No se pudieron actualizar los datos del usuario.']);
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
    }

    public function test_todos_los_campos_del_formulario_se_guardan_juntos(): void
    {
        $data = ['nombres' => 'Juanito', 'apellidos' => 'Perez', 'apodo' => 'Juancit',
            'correo' => 'juan@example.invalid', 'telefono' => '987654321',
            'tipo_documento' => 'PASAPORTE', 'numero_documento' => '74581236',
            'fecha_nacimiento' => '1998-04-15', 'genero' => 'Varon', 'direccion' => 'Av. Los Olivos 100'];
        $response = $this->putJson('/api/usuarios/1', $data)->assertOk()
            ->assertJsonPath('nombre', 'Juanito');
        foreach (array_diff_key($data, ['nombres' => true]) as $key => $value) {
            $response->assertJsonPath($key, $value);
        }
        $this->assertDatabaseHas('usuarios', ['id' => 1] + $data);
    }

    public function test_fecha_de_nacimiento_parcial_y_validacion_sin_cambios(): void
    {
        $this->putJson('/api/usuarios/1', ['fecha_nacimiento' => '2000-02-29'])->assertOk()
            ->assertJsonPath('fecha_nacimiento', '2000-02-29')->assertJsonPath('nombre', 'Nombre');
        $before = DB::table('usuarios')->get()->toJson();
        foreach ([null, '', '1998-02-30', '15/04/1998', 'texto', '0999-01-01', today()->addDay()->toDateString()] as $date) {
            $this->put('/api/usuarios/1', ['fecha_nacimiento' => $date, 'nombres' => 'No guardar'])
                ->assertUnprocessable()->assertJsonValidationErrors('fecha_nacimiento');
        }
        $this->assertSame($before, DB::table('usuarios')->get()->toJson());
    }
}
