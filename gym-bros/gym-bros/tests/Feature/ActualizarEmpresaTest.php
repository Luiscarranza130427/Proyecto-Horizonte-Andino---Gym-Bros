<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ActualizarEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        \Illuminate\Support\Facades\Schema::create('suscripciones', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->id(); $table->unsignedBigInteger('id_empresas');
            $table->string('estado'); $table->date('fecha_inicio'); $table->date('fecha_fin');
        });
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        (require database_path('migrations/2026_08_21_224135_create_empresas.php'))->up();
        \Illuminate\Support\Facades\Schema::create('usuarios', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('id_empresas');
        });
        $empresa = ['nombre' => 'Gym QA', 'nombre_gerente' => 'Gerente QA', 'telefono' => '999999999',
            'correo' => 'gym@example.invalid', 'estado' => true, 'fecha_registro' => '2026-09-01',
            'logo' => 'empresas/logo.webp', 'color_1' => '#111111', 'color_2' => '#eeeeee',
            'banner_1' => 'banner.webp', 'link_boton_1' => 'https://example.invalid'];
        foreach (['lunes', 'martes', 'miercoles', 'jueves', 'viernes'] as $dia) {
            $empresa['horario_inicio_'.$dia] = 8;
            $empresa['horario_fin_'.$dia] = 20;
        }
        DB::table('empresas')->insert([['id' => 1] + $empresa, ['id' => 2] + $empresa]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_edicion_parcial_preserva_excluidos_y_empresa_ajena(): void
    {
        $otra = DB::table('empresas')->where('id', 2)->first();
        $this->putJson('/api/empresas/1', ['nombre' => 'Gym actualizado', 'id' => 2, 'color_1' => '#ff0000',
            'color_2' => '#00ff00', 'banner_1' => 'nuevo', 'banner_2' => 'nuevo', 'banner_3' => 'nuevo',
            'link_boton_1' => 'nuevo', 'link_boton_2' => 'nuevo', 'link_boton_3' => 'nuevo'])
            ->assertOk()->assertJsonPath('data.id', 1)->assertJsonPath('data.nombre', 'Gym actualizado')
            ->assertJsonPath('data.color_1', '#111111')->assertJsonPath('data.color_2', '#eeeeee')
            ->assertJsonPath('data.banner_1', 'banner.webp')->assertJsonPath('data.banner_2', null)
            ->assertJsonPath('data.banner_3', null)->assertJsonPath('data.link_boton_1', 'https://example.invalid')
            ->assertJsonPath('data.link_boton_2', null)->assertJsonPath('data.link_boton_3', null)
            ->assertJsonPath('data.telefono', '999999999');
        $this->assertEquals($otra, DB::table('empresas')->where('id', 2)->first());
    }

    public function test_actualiza_datos_generales_logo_y_horarios(): void
    {
        $datos = ['nombre_gerente' => 'Nuevo gerente', 'region' => 'Lima', 'ruc' => '20123456789',
            'enlace_web' => 'https://example.invalid/gym', 'direccion' => 'Direccion QA', 'telefono' => '912345678',
            'correo' => 'nuevo@example.invalid', 'estado' => false, 'fecha_registro' => '2026-09-14',
            'logo' => 'empresas/nuevo.webp', 'horario_inicio_lunes' => 8.5, 'horario_fin_domingo' => 18];
        $this->putJson('/api/empresas/1', $datos)->assertOk()->assertJsonPath('data.logo', 'empresas/nuevo.webp');
        $this->assertDatabaseHas('empresas', ['id' => 1] + $datos);
    }

    public function test_solo_campos_nullable_aceptan_null(): void
    {
        $this->putJson('/api/empresas/1', ['region' => null, 'ruc' => null, 'direccion' => null,
            'enlace_web' => null, 'horario_inicio_sabado' => null, 'horario_fin_domingo' => null])->assertOk();
        foreach (['nombre', 'nombre_gerente', 'telefono', 'correo', 'estado', 'fecha_registro', 'logo', 'horario_fin_lunes'] as $campo) {
            $this->putJson('/api/empresas/1', [$campo => null])->assertUnprocessable()->assertJsonValidationErrors($campo);
        }
    }

    public function test_invalidos_devuelven_json_sin_cambios_incluso_sin_accept(): void
    {
        $antes = DB::table('empresas')->get()->toJson();
        foreach (['correo' => 'invalido', 'nombre' => str_repeat('x', 151), 'telefono' => '1234567890',
            'region' => 'NoExiste', 'estado' => 'talvez', 'fecha_registro' => '2026-02-30',
            'horario_inicio_lunes' => '08:30', 'horario_fin_lunes' => 25, 'horario_fin_martes' => -1,
            'horario_fin_jueves' => 12.123] as $campo => $valor) {
            $this->put('/api/empresas/1', [$campo => $valor, 'nombre_gerente' => 'No persistir'])
                ->assertUnprocessable()->assertJsonValidationErrors($campo);
        }
        $this->assertSame($antes, DB::table('empresas')->get()->toJson());
    }

    public function test_peticion_vacia_o_solo_excluidos_no_simula_actualizacion(): void
    {
        foreach ([[], ['color_1' => '#000000'], ['id' => 2], ['campo_desconocido' => true]] as $body) {
            $this->putJson('/api/empresas/1', $body)->assertUnprocessable()->assertJsonValidationErrors('datos');
        }
    }

    public function test_empresa_inexistente_y_listado_actual_se_conserva(): void
    {
        $this->put('/api/empresas/999', ['nombre' => 'QA'])->assertNotFound()->assertJsonStructure(['message']);
        $this->getJson('/api/empresas')->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('data.0.fecha_registro', '2026-09-01');
    }

    public function test_personalizacion_modifica_solo_colores_banners_y_links(): void
    {
        $antes = (array) DB::table('empresas')->where('id', 1)->first();
        $otra = DB::table('empresas')->where('id', 2)->first();
        $datos = ['color_1' => '#ff0000', 'color_2' => '#00ff00', 'banner_1' => 'empresas/banner1.webp',
            'banner_2' => 'empresas/banner2.webp', 'banner_3' => 'empresas/banner3.webp',
            'link_boton_1' => 'https://example.invalid/1', 'link_boton_2' => 'https://example.invalid/2',
            'link_boton_3' => 'https://example.invalid/3'];
        $this->putJson('/api/empresas/1/personalizacion', $datos + ['id' => 2, 'nombre' => 'No cambiar',
            'logo' => 'no-cambiar.webp', 'estado' => false, 'correo' => 'otro@example.invalid',
            'horario_fin_lunes' => 10])->assertOk()->assertJsonPath('data.id', 1)
            ->assertJsonPath('data.color_1', '#ff0000')->assertJsonPath('data.nombre', 'Gym QA');
        $despues = (array) DB::table('empresas')->where('id', 1)->first();
        foreach ($antes as $campo => $valor) {
            if ($campo !== 'updated_at') {
                $this->assertEquals($datos[$campo] ?? $valor, $despues[$campo], $campo);
            }
        }
        $this->assertEquals($otra, DB::table('empresas')->where('id', 2)->first());
    }

    public function test_personalizacion_parcial_conserva_omitidos_y_permite_limpiar_banners_y_links(): void
    {
        $this->putJson('/api/empresas/1/personalizacion', ['color_2' => '#ffffff'])->assertOk()
            ->assertJsonPath('data.color_1', '#111111')->assertJsonPath('data.banner_1', 'banner.webp');
        $this->putJson('/api/empresas/1/personalizacion', ['banner_1' => null, 'link_boton_1' => null])->assertOk()
            ->assertJsonPath('data.banner_1', null)->assertJsonPath('data.link_boton_1', null)
            ->assertJsonPath('data.color_2', '#ffffff');
        $this->putJson('/api/empresas/1/personalizacion', ['banner_1' => str_repeat('a', 300),
            'link_boton_1' => str_repeat('a', 200)])->assertOk();
    }

    public function test_personalizacion_invalida_no_guarda_cambios_y_devuelve_json(): void
    {
        $antes = DB::table('empresas')->get()->toJson();
        foreach ([['color_1' => null], ['color_2' => ''], ['color_1' => str_repeat('a', 11)],
            ['banner_1' => str_repeat('a', 301)], ['link_boton_2' => str_repeat('a', 201)],
            ['banner_2' => ['archivo']], ['color_2' => 123]] as $invalido) {
            $this->put('/api/empresas/1/personalizacion', $invalido + ['banner_3' => 'no-persistir'])
                ->assertUnprocessable()->assertJsonValidationErrors(array_keys($invalido));
        }
        foreach ([[], ['nombre' => 'No editable'], ['id' => 2]] as $body) {
            $this->putJson('/api/empresas/1/personalizacion', $body)->assertUnprocessable()->assertJsonValidationErrors('datos');
        }
        $this->put('/api/empresas/999/personalizacion', ['color_1' => '#ff0000'])
            ->assertNotFound()->assertJsonStructure(['message']);
        $this->assertSame($antes, DB::table('empresas')->get()->toJson());
    }
}
