<?php

namespace Tests\Feature;

use App\Models\Plan;
use App\Models\Suscripcion;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ResumenWebTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        Carbon::setTestNow('2026-09-14 10:00:00');
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $table) {
            $table->id();
            $table->boolean('estado')->default(true);
        });
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('tipo_usuario');
            $table->unsignedBigInteger('id_empresas')->nullable();
            $table->boolean('estado')->default(true);
        });
        Schema::create('ejercicios', function (Blueprint $table) {
            $table->id();
            $table->boolean('estado');
        });
        foreach (['2026_08_29_170121_create_empresa_ejercicio_table.php',
            '2026_08_21_224524_create_planes.php', '2026_08_21_224533_create_suscripciones.php'] as $file) {
            (require database_path('migrations/'.$file))->up();
        }
        DB::table('empresas')->insert([['id' => 1, 'estado' => true], ['id' => 2, 'estado' => false]]);
        DB::table('usuarios')->insert([
            ['id' => 1, 'tipo_usuario' => 'Administrador', 'id_empresas' => 1, 'estado' => true],
            ['id' => 2, 'tipo_usuario' => 'Empresa', 'id_empresas' => 1, 'estado' => true],
            ['id' => 3, 'tipo_usuario' => 'Entrenador', 'id_empresas' => 1, 'estado' => true],
            ['id' => 4, 'tipo_usuario' => 'Usuario', 'id_empresas' => 1, 'estado' => false],
            ['id' => 5, 'tipo_usuario' => 'Empresa', 'id_empresas' => 2, 'estado' => true],
        ]);
        DB::table('ejercicios')->insert([['id' => 1, 'estado' => true], ['id' => 2, 'estado' => false],
            ['id' => 3, 'estado' => true], ['id' => 4, 'estado' => true], ['id' => 5, 'estado' => true]]);
        DB::table('empresa_ejercicio')->insert([
            ['id_empresas' => 1, 'id_ejercicios' => 1, 'estado' => true],
            ['id_empresas' => 1, 'id_ejercicios' => 2, 'estado' => true],
            ['id_empresas' => 1, 'id_ejercicios' => 3, 'estado' => false],
            ['id_empresas' => 2, 'id_ejercicios' => 1, 'estado' => true],
            ['id_empresas' => 2, 'id_ejercicios' => 4, 'estado' => true],
        ]);
        DB::table('planes')->insert(['id' => 1, 'nombre' => 'Plan SaaS QA', 'descripcion' => 'Prueba',
            'precio_original' => 100, 'precio_inicial' => 80, 'duracion_dias' => 30, 'limite_usuarios' => 50,
            'activo' => true, 'enlace_whatsapp' => 'https://example.invalid']);
        DB::table('suscripciones')->insert(['id' => 1, 'id_empresas' => 1, 'id_planes' => 1,
            'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-09-30', 'estado' => 'activa']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_empresa_y_entrenador_reciben_solo_cantidades_de_su_empresa(): void
    {
        foreach ([2, 3] as $id) {
            $this->getJson('/api/usuarios/'.$id.'/resumen-web?tipo_usuario=Administrador&id_empresas=2')
                ->assertOk()->assertJsonPath('data.cantidad_usuarios', 4)
                ->assertJsonPath('data.cantidad_ejercicios', 1)
                ->assertJsonMissingPath('data.cantidad_empresas')
                ->assertJsonPath('data.plan_empresa.nombre', 'Plan SaaS QA')
                ->assertJsonPath('data.plan_empresa.id_suscripcion', 1);
        }
        $this->getJson('/api/usuarios/5/resumen-web')->assertOk()
            ->assertJsonPath('data.cantidad_usuarios', 1)->assertJsonPath('data.cantidad_ejercicios', 2)
            ->assertJsonPath('data.plan_empresa', null);
    }

    public function test_administrador_cuenta_todos_incluidos_inactivos_y_no_duplica_ejercicios(): void
    {
        $this->getJson('/api/usuarios/1/resumen-web')->assertOk()
            ->assertJsonPath('data.cantidad_usuarios', 5)->assertJsonPath('data.cantidad_empresas', 2)
            ->assertJsonPath('data.cantidad_ejercicios', 5)->assertJsonPath('data.alcance', 'global');
    }

    public function test_roles_no_permitidos_inactivos_y_usuario_ausente(): void
    {
        DB::table('usuarios')->where('id', 4)->update(['estado' => true]);
        $this->get('/api/usuarios/4/resumen-web')->assertForbidden()->assertJsonStructure(['message']);
        DB::table('usuarios')->where('id', 2)->update(['estado' => false]);
        $this->get('/api/usuarios/2/resumen-web')->assertForbidden();
        $this->get('/api/usuarios/999/resumen-web')->assertNotFound()->assertJsonStructure(['message']);
    }

    public function test_empresa_ausente_no_expone_totales_globales_y_admin_no_requiere_empresa(): void
    {
        DB::table('usuarios')->whereIn('id', [1, 2])->update(['id_empresas' => null]);
        $this->getJson('/api/usuarios/2/resumen-web')->assertUnprocessable()->assertJsonValidationErrors('id_empresas');
        $this->getJson('/api/usuarios/1/resumen-web')->assertOk()
            ->assertJsonPath('data.cantidad_usuarios', 5)->assertJsonPath('data.plan_empresa', null);
    }

    public function test_suscripcion_debe_estar_activa_y_vigente_incluidos_ambos_extremos(): void
    {
        foreach (['pendiente', 'vencida', 'cancelada', 'suspendida'] as $estado) {
            DB::table('suscripciones')->where('id', 1)->update(['estado' => $estado]);
            $this->getJson('/api/usuarios/2/resumen-web')->assertOk()->assertJsonPath('data.plan_empresa', null);
        }
        foreach ([['2026-08-01', '2026-09-13'], ['2026-09-15', '2026-10-01']] as [$inicio, $fin]) {
            DB::table('suscripciones')->where('id', 1)->update(['estado' => 'activa', 'fecha_inicio' => $inicio, 'fecha_fin' => $fin]);
            $this->getJson('/api/usuarios/2/resumen-web')->assertOk()->assertJsonPath('data.plan_empresa', null);
        }
        DB::table('suscripciones')->where('id', 1)->update(['fecha_inicio' => '2026-09-14', 'fecha_fin' => '2026-09-14']);
        DB::table('planes')->where('id', 1)->update(['activo' => false]);
        $this->getJson('/api/usuarios/2/resumen-web')->assertOk()->assertJsonPath('data.plan_empresa.id', 1);
    }

    public function test_varias_suscripciones_selecciona_inicio_mas_reciente_y_luego_id(): void
    {
        foreach ([2, 3] as $id) {
            DB::table('suscripciones')->insert(['id' => $id, 'id_empresas' => 1, 'id_planes' => 1,
                'fecha_inicio' => '2026-09-14', 'fecha_fin' => '2026-09-30', 'estado' => 'activa']);
        }
        $this->getJson('/api/usuarios/2/resumen-web')->assertOk()->assertJsonPath('data.plan_empresa.id_suscripcion', 3);
    }

    public function test_modelo_y_relacion_apuntan_al_plan_saas(): void
    {
        $this->assertSame('planes', (new Plan)->getTable());
        $this->assertSame('Plan SaaS QA', Suscripcion::findOrFail(1)->plan->nombre);
    }

    public function test_roles_en_minusculas_y_empresa_sin_ejercicios(): void
    {
        DB::table('usuarios')->where('id', 2)->update(['tipo_usuario' => 'empresa']);
        DB::table('empresa_ejercicio')->where('id_empresas', 1)->delete();
        $this->getJson('/api/usuarios/2/resumen-web')->assertOk()
            ->assertJsonPath('data.cantidad_ejercicios', 0)->assertJsonMissingPath('data.cantidad_empresas');
        DB::table('usuarios')->where('id', 1)->update(['tipo_usuario' => 'administrador']);
        $this->getJson('/api/usuarios/1/resumen-web')->assertOk()->assertJsonPath('data.cantidad_empresas', 2);
    }

    public function test_catalogo_planes_existente_devuelve_planes_saas(): void
    {
        $this->getJson('/api/planes')->assertOk()->assertJsonPath('data.0.nombre', 'Plan SaaS QA')
            ->assertJsonCount(1, 'data');
    }
}
