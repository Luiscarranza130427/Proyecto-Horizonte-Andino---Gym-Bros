<?php

namespace Tests\Feature;

use App\Models\Alimento;
use App\Models\ComidaAlimento;
use App\Services\Alimentacion\CalculadorPorcionesService;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class GeneradorAlimentacionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        Carbon::setTestNow('2026-09-12 10:00:00');
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null, 'alimentacion.habilitado' => true]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $table) {
            $table->id();
            $table->boolean('estado');
        });
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_empresas')->constrained('empresas');
            $table->boolean('estado');
            $table->date('fecha_nacimiento');
        });
        foreach (['2026_08_21_224244_create_evaluaciones_fisicas.php',
            '2026_09_02_230717_add_id_usuario_to_evaluaciones_fisicas_table.php',
            '2026_08_21_224403_create_alimentos.php', '2026_08_21_224411_create_planes_alimentacion.php',
            '2026_08_21_224435_create_comidas.php', '2026_08_21_224436_create_comida_alimentos.php',
            '2026_08_21_224445_create_preferencias_alimentarias.php',
            '2026_09_12_000001_add_altura_unidad_to_evaluaciones_fisicas.php',
            '2026_09_12_000002_prepare_meal_plan_generation.php',
            '2026_09_12_120000_make_alimentacion_review_optional.php',
            '2026_09_12_130000_use_food_preferences_only.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        DB::table('empresas')->insert(['id' => 1, 'estado' => true]);
        DB::table('usuarios')->insert([
            ['id' => 1, 'id_empresas' => 1, 'estado' => true, 'fecha_nacimiento' => '1996-01-01'],
            ['id' => 2, 'id_empresas' => 1, 'estado' => true, 'fecha_nacimiento' => '1996-01-01'],
        ]);
        $this->evaluacion();
        DB::table('perfiles_alimentarios')->insert(['id_usuarios' => 1] + $this->perfilDatos());
        // Synthetic fixtures validate mathematics only. Never insert these in the real catalog.
        foreach ([['proteina', 100, 25, 0, 0], ['carbohidrato', 200, 0, 50, 0],
            ['grasa', 900, 0, 0, 100], ['fruta', 40, 0, 10, 0], ['verdura', 20, 0, 5, 0]] as $grupo) {
            for ($variante = 1; $variante <= 3; $variante++) {
                Alimento::create(['nombre' => 'Fixture '.$grupo[0].' '.$variante, 'tipo' => $grupo[0],
                    'calorias' => $grupo[1], 'proteinas' => $grupo[2], 'carbohidratos' => $grupo[3],
                    'grasas' => $grupo[4], 'fibra' => 0, 'base_unidad' => 'gramos', 'estado_preparacion' => 'fixture',
                    'fuente_nutricional' => 'DATOS SINTETICOS EXCLUSIVOS DE QA', 'nutricion_verificada' => true,
                    'restricciones_verificadas' => true, 'grupo_menu' => $grupo[0],
                    'tipos_comida' => array_keys(config('alimentacion.grupos_comida')),
                    'porcion_min' => 1, 'porcion_max' => $grupo[0] === 'grasa' ? 60 : 600, 'paso_porcion' => 1]);
            }
        }
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function evaluacion(array $overrides = []): int
    {
        return DB::table('evaluaciones_fisicas')->insertGetId(array_replace([
            'id_usuarios' => 1, 'nivel_experiencia' => '1a3meses', 'actividad_diaria' => 'sedentario',
            'objetivo' => 'salud', 'edad' => 30, 'peso' => 70, 'altura' => 175, 'altura_unidad' => 'cm',
            'porcentaje_grasa' => 20, 'masa_muscular' => 30, 'cintura' => 80, 'pecho' => 90,
            'brazo' => 30, 'muslo' => 50, 'cadera' => 90, 'dias_semana' => 3, 'eleccion_dias' => 'Lunes',
            'tiempo_sesion_min' => 60, 'restricciones' => 'sin-restricciones', 'fecha_evaluacion' => '2026-09-12',
        ], $overrides));
    }

    public function test_flutter_creates_profile_without_professional_review_and_returns_saved_checkboxes(): void
    {
        $body = ['sexo_calculo' => 'masculino', 'embarazo' => false, 'lactancia' => false,
            'requiere_plan_clinico' => false, 'apto_plan_general' => true,
            'alergias' => [], 'intolerancias' => [], 'preferencias' => [
                ['id_alimentos' => 1, 'tipo' => 'preferido'], ['id_alimentos' => 2, 'tipo' => 'rechazado'],
            ]];
        $put = $this->putJson('/api/usuarios/2/perfil-alimentario', $body)->assertOk()
            ->assertJsonPath('data.revision_profesional', null)->assertJsonPath('data.revisado_en', null)
            ->assertJsonPath('data.preferencias.1.tipo', 'rechazado');
        $this->getJson('/api/usuarios/2/perfil-alimentario')->assertOk()->assertExactJson($put->json());
    }

    private function perfilDatos(): array
    {
        return ['sexo_calculo' => 'masculino', 'embarazo' => false, 'lactancia' => false,
            'requiere_plan_clinico' => false, 'apto_plan_general' => true,
            'revision_profesional' => 'Revision simulada QA', 'revisado_en' => '2026-09-12'];
    }

    public function test_checkbox_only_schema_and_active_catalog(): void
    {
        foreach (['restricciones_alimentarias', 'alimento_restriccion', 'usuario_restriccion_alimentaria'] as $table) {
            $this->assertFalse(Schema::hasTable($table));
        }
        Alimento::where('id', 1)->update(['activo' => false]);
        $ids = array_column($this->getJson('/api/alimentos')->assertOk()->json('data'), 'id');
        $this->assertCount(14, $ids);
        $this->assertNotContains(1, $ids);
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'preferencias' => [['id_alimentos' => 1, 'tipo' => 'preferido'], ['id_alimentos' => 2, 'tipo' => 'rechazado']]]))->assertOk();
        $data = $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()->json('data');
        foreach ($data['dias'] as $dia) {
            foreach ($dia['comidas'] as $comida) {
                $this->assertNotContains(1, array_column($comida['alimentos'], 'id_alimentos'));
                $this->assertNotContains(2, array_column($comida['alimentos'], 'id_alimentos'));
            }
        }
    }

    private function payload(array $overrides = []): array
    {
        return array_replace(['fecha_inicio' => '2026-09-12', 'duracion_dias' => 2, 'cantidad_comidas' => 3,
            'horarios' => ['desayuno' => '08:00', 'almuerzo' => '13:00', 'cena' => '19:00']], $overrides);
    }

    public function test_consulta_ultimo_plan_por_usuario_con_detalle_sin_escrituras(): void
    {
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
        $ultimo = $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()->json('data');
        $antes = DB::table('planes_alimentacion')->get()->toJson();
        $this->get('/api/usuarios/1/plan-alimentacion')->assertOk()->assertExactJson(['data'=>$ultimo]);
        $this->assertSame($antes, DB::table('planes_alimentacion')->get()->toJson());
        $this->get('/api/usuarios/2/plan-alimentacion')->assertNotFound()->assertJsonStructure(['message']);
        $this->get('/api/usuarios/999/plan-alimentacion')->assertNotFound()->assertJsonStructure(['message']);
        DB::table('planes_alimentacion')->update(['calculo'=>null]);
        $this->get('/api/usuarios/1/plan-alimentacion')->assertNotFound();
    }

    public function test_consulta_ultimo_plan_respeta_autorizacion_existente(): void
    {
        $this->sinSesion();
        $this->withHeader('Authorization','Bearer invalido')->getJson('/api/usuarios/1/plan-alimentacion')
            ->assertUnauthorized();
        $this->flushHeaders();
        // El modelo User de Laravel no es una cuenta del dominio: no abre sesion.
        $this->actingAs(new \App\Models\User());
        $this->getJson('/api/usuarios/1/plan-alimentacion')->assertUnauthorized();
    }

    public function test_sesion_simulada_de_desarrollo_ya_no_da_acceso_en_ningun_entorno(): void
    {
        config(['alimentacion.permitir_sin_sesion_local'=>true]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
        $this->sinSesion();
        foreach (['local', 'testing'] as $entorno) {
            $this->app->instance('env', $entorno);
            $this->withHeader('Authorization','Bearer desarrollo-sin-backend-1')
                ->getJson('/api/usuarios/1/plan-alimentacion')->assertUnauthorized();
            $this->flushHeaders();
            $this->getJson('/api/usuarios/1/plan-alimentacion')->assertUnauthorized();
            $this->postJson('/api/planesalimentacion/generar/1',$this->payload())->assertUnauthorized();
        }
    }

    public function test_generates_days_portions_totals_and_preserves_snapshot_and_history(): void
    {
        $data = $this->postJson('/api/planesalimentacion/generar/1', $this->payload(['id_usuarios' => 2]))
            ->assertCreated()->assertJsonPath('data.id_usuarios', 1)->json('data');
        $this->assertEquals(2308.25, $data['calculo']['objetivos']['calorias']);
        $this->assertCount(2, $data['dias']);
        $this->assertDatabaseCount('comidas', 6);
        $this->assertDatabaseCount('comida_alimentos', 24);
        $calculador = app(CalculadorPorcionesService::class);
        foreach ($data['dias'] as $dia) {
            $sumas = [];
            foreach ($dia['comidas'] as $comida) {
                $nutrientes = [];
                foreach ($comida['alimentos'] as $fila) {
                    $a = Alimento::findOrFail($fila['id_alimentos'])->toArray();
                    $this->assertGreaterThanOrEqual($a['porcion_min'], $fila['cantidad']);
                    $this->assertLessThanOrEqual($a['porcion_max'], $fila['cantidad']);
                    $this->assertEqualsWithDelta(0, fmod($fila['cantidad'], $a['paso_porcion']), 0.00001);
                    $nutrientes[] = $calculador->nutrientes($a, $fila['cantidad'], $fila['unidad']);
                }
                $this->assertEquals($calculador->sumar($nutrientes), $comida['totales']);
                $sumas[] = $comida['totales'];
            }
            $this->assertEquals($calculador->sumar($sumas), $dia['totales']);
            $this->assertTrue($calculador->cumple($dia['totales'], $data['calculo']['objetivos']));
        }
        $ids = array_map(fn ($c) => array_column($c['alimentos'], 'id_alimentos'), $data['dias'][0]['comidas']);
        $this->assertNotEquals($ids[0][0], $ids[1][0]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
        $this->assertDatabaseCount('planes_alimentacion', 2);
        Alimento::query()->update(['calorias' => 1]);
        $this->getJson('/api/usuarios/1/planesalimentacion/'.$data['id'])->assertOk()->assertExactJson(['data' => $data]);
        $this->get('/api/usuarios/2/planesalimentacion/'.$data['id'])->assertNotFound()->assertJsonStructure(['message']);
    }

    public function test_last_evaluation_uses_date_then_id_and_never_another_user(): void
    {
        $latest = $this->evaluacion(['peso' => 72]);
        $this->evaluacion(['fecha_evaluacion' => '2026-09-01', 'peso' => 80]);
        $this->evaluacion(['id_usuarios' => 2, 'peso' => 90]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()
            ->assertJsonPath('data.id_evaluaciones_fisicas', $latest)->assertJsonPath('data.calculo.peso_kg', 72);
    }

    #[DataProvider('objetivos')]
    public function test_all_objectives_and_meal_counts_have_feasible_totals(string $objetivo, int $cantidad): void
    {
        DB::table('evaluaciones_fisicas')->update(['objetivo' => $objetivo]);
        $horarios = array_combine(array_keys(config('alimentacion.distribuciones.'.$cantidad)),
            $cantidad === 3 ? ['08:00', '13:00', '19:00'] : ($cantidad === 4 ? ['08:00', '13:00', '16:00', '19:00'] : ['08:00', '10:00', '13:00', '16:00', '19:00']));
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload(['cantidad_comidas' => $cantidad, 'horarios' => $horarios]))
            ->assertCreated()->assertJsonCount($cantidad, 'data.dias.0.comidas');
    }

    public static function objetivos(): array
    {
        $casos = [];
        foreach (['salud', 'perdida_peso', 'ganancia_muscular', 'resistencia', 'recomposicion', 'aumento_fuerza'] as $objetivo) {
            foreach ([3, 4, 5] as $cantidad) {
                $casos[] = [$objetivo, $cantidad];
            }
        }
        return $casos;
    }

    #[DataProvider('invalidos')]
    public function test_invalid_inputs_return_json_without_writes(string $campo, mixed $valor): void
    {
        $this->post('/api/planesalimentacion/generar/1', $this->payload([$campo => $valor]))
            ->assertUnprocessable()->assertJsonStructure(['errors']);
        $this->assertDatabaseCount('planes_alimentacion', 0);
    }

    public static function invalidos(): array
    {
        return [['duracion_dias', 0], ['duracion_dias', 15], ['duracion_dias', 2.5],
            ['cantidad_comidas', 2], ['cantidad_comidas', []], ['cantidad_comidas', null],
            ['fecha_inicio', '2026-02-30'], ['fecha_inicio', '2026-09-11'], ['fecha_inicio', '2027-01-01'],
            ['horarios', []], ['horarios', '08:00'], ['horarios', ['desayuno' => '25:00', 'almuerzo' => '13:00', 'cena' => '19:00']],
            ['horarios', ['desayuno' => '13:00', 'almuerzo' => '08:00', 'cena' => '19:00']],
            ['horarios', ['desayuno' => '08:00', 'almuerzo' => '08:00', 'cena' => '19:00']],
            ['horarios', ['desayuno' => '08:00', 'almuerzo' => '13:00', 'otro' => '19:00']]];
    }

    public function test_incomplete_catalog_preferences_and_rejections_fail_closed(): void
    {
        DB::table('preferencias_alimentarias')->insert([
            ['id_usuarios' => 1, 'id_alimentos' => 1, 'activo' => true, 'tipo' => 'rechazado'],
            ['id_usuarios' => 1, 'id_alimentos' => 2, 'activo' => true, 'tipo' => 'rechazado'],
        ]);
        $data = $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()->json('data');
        foreach ($data['dias'] as $dia) {
            foreach ($dia['comidas'] as $comida) {
                $this->assertNotContains(1, array_column($comida['alimentos'], 'id_alimentos'));
                $this->assertNotContains(2, array_column($comida['alimentos'], 'id_alimentos'));
            }
        }
        Alimento::where('id', 3)->update(['activo' => false]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable()->assertJsonValidationErrors('alimentos');
        Alimento::where('id', 3)->update(['activo' => true, 'nutricion_verificada' => false]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable();
        DB::table('preferencias_alimentarias')->where('id_alimentos', 2)->update(['tipo' => null]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable()->assertJsonValidationErrors('preferencias');
        $this->assertDatabaseCount('planes_alimentacion', 1);
    }

    #[DataProvider('perfilesInvalidos')]
    public function test_unsupported_profiles_and_stale_data_do_not_generate(string $tabla, array $datos): void
    {
        DB::table($tabla)->update($datos);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable();
        $this->assertDatabaseCount('planes_alimentacion', 0);
    }

    public static function perfilesInvalidos(): array
    {
        return [['perfiles_alimentarios', ['embarazo' => true]], ['perfiles_alimentarios', ['lactancia' => true]],
            ['perfiles_alimentarios', ['requiere_plan_clinico' => true]], ['perfiles_alimentarios', ['apto_plan_general' => false]],
            ['usuarios', ['estado' => false]], ['empresas', ['estado' => false]],
            ['usuarios', ['fecha_nacimiento' => '2010-01-01']], ['usuarios', ['fecha_nacimiento' => '1940-01-01']],
            ['evaluaciones_fisicas', ['altura_unidad' => null]], ['evaluaciones_fisicas', ['altura' => 1.76]],
            ['evaluaciones_fisicas', ['altura' => 250]], ['evaluaciones_fisicas', ['peso' => 9999]],
            ['evaluaciones_fisicas', ['edad' => 31]], ['evaluaciones_fisicas', ['fecha_evaluacion' => '2025-01-01']]];
    }

    public function test_missing_user_evaluation_and_disabled_gate(): void
    {
        $this->post('/api/planesalimentacion/generar/999', $this->payload())->assertNotFound()->assertJsonStructure(['message']);
        $this->postJson('/api/planesalimentacion/generar/2', $this->payload())->assertUnprocessable();
        config(['alimentacion.habilitado' => false]);
        $this->post('/api/planesalimentacion/generar/1', $this->payload())->assertStatus(503)->assertJsonStructure(['message']);
        config(['alimentacion.habilitado' => true]);
        DB::table('perfiles_alimentarios')->delete();
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable();
        $this->assertDatabaseCount('planes_alimentacion', 0);
    }

    public function test_impossible_portions_and_late_storage_failure_do_not_leave_partial_rows(): void
    {
        Alimento::query()->update(['porcion_max' => 1]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable()->assertJsonValidationErrors('porciones');
        Alimento::query()->update(['porcion_max' => 600]);
        $insertados = 0;
        ComidaAlimento::created(function () use (&$insertados) {
            if (++$insertados === 5) {
                throw new \RuntimeException('Fallo QA despues de persistir alimentos');
            }
        });
        try {
            $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertStatus(500);
            $this->assertSame(5, $insertados);
            foreach (['planes_alimentacion', 'comidas', 'comida_alimentos'] as $tabla) {
                $this->assertDatabaseCount($tabla, 0);
            }
        } finally {
            ComidaAlimento::flushEventListeners();
        }
    }

    public function test_profile_and_food_apis_validate_relations_and_preserve_other_users(): void
    {
        $this->getJson('/api/restriccionesalimentarias')->assertNotFound();
        $this->postJson('/api/restriccionesalimentarias', ['codigo' => 'leche', 'nombre' => 'Leche'])->assertNotFound();
        $datos = $this->flutterBody(['preferencias' => [['id_alimentos' => 2, 'tipo' => 'rechazado']]]);
        $this->putJson('/api/usuarios/1/perfil-alimentario', $datos + ['id_usuarios' => 2])->assertOk()->assertJsonPath('data.id_usuarios', 1);
        $this->assertDatabaseMissing('perfiles_alimentarios', ['id_usuarios' => 2]);
        $this->putJson('/api/usuarios/999/perfil-alimentario', $datos)->assertNotFound();
        $food = Alimento::findOrFail(1)->toArray();
        unset($food['restricciones_verificadas']);
        $food['gramos_por_unidad'] = null;
        $food['densidad_g_ml'] = null;
        $this->putJson('/api/alimentos/1/nutricion', $food)->assertOk();
        foreach (['proteinas' => -1, 'calorias' => 9999, 'base_unidad' => 'taza', 'fuente_nutricional' => '',
            'porcion_min' => 700, 'paso_porcion' => 0, 'restricciones' => [999]] as $key => $value) {
            $this->putJson('/api/alimentos/1/nutricion', array_replace($food, [$key => $value]))->assertUnprocessable();
        }
    }

    public function test_composite_nutrients_and_fractional_steps_are_recalculated_after_rounding(): void
    {
        foreach ([['proteina', 138, 25, 5, 2], ['carbohidrato', 226, 2, 50, 2],
            ['grasa', 900, 0, 0, 100], ['fruta', 48, 1, 11, 0], ['verdura', 28, 2, 5, 0]] as $g) {
            Alimento::where('grupo_menu', $g[0])->update(['calorias' => $g[1], 'proteinas' => $g[2],
                'carbohidratos' => $g[3], 'grasas' => $g[4], 'paso_porcion' => 2.5, 'porcion_min' => 2.5]);
        }
        $data = $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()->json('data');
        foreach ($data['dias'] as $dia) {
            $this->assertTrue(app(CalculadorPorcionesService::class)->cumple($dia['totales'], $data['calculo']['objetivos']));
            foreach ($dia['comidas'] as $comida) {
                foreach ($comida['alimentos'] as $a) {
                    $this->assertEqualsWithDelta(0, fmod($a['cantidad'], 2.5), 0.00001);
                }
            }
        }
    }

    public function test_malformed_catalog_excluded_and_unknown_units_rejected(): void
    {
        Alimento::where('grupo_menu', 'proteina')->update(['tipos_comida' => 'no_es_un_array']);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable();
        $calc = app(CalculadorPorcionesService::class);
        foreach ([['unidad', null, null], ['taza', 50, 1], ['mililitros', 50, null]] as [$unidad, $peso, $densidad]) {
            $a = Alimento::findOrFail(1)->toArray();
            $a['gramos_por_unidad'] = $peso;
            $a['densidad_g_ml'] = $densidad;
            try {
                $calc->nutrientes($a, 100, $unidad);
                $this->fail('La conversion invalida debe rechazarse.');
            } catch (\Illuminate\Validation\ValidationException $e) {
                $this->assertArrayHasKey('unidad', $e->errors());
            }
        }
    }

    public function test_new_schema_gate_and_audit_never_change_legacy_rows(): void
    {
        DB::table('evaluaciones_fisicas')->update(['altura' => 1.76, 'altura_unidad' => null]);
        $antes = DB::table('evaluaciones_fisicas')->get()->toJson();
        $this->artisan('alimentacion:auditar-alturas')->assertSuccessful();
        $this->assertSame($antes, DB::table('evaluaciones_fisicas')->get()->toJson());
        (require database_path('migrations/2026_09_12_000002_prepare_meal_plan_generation.php'))->down();
        $this->post('/api/planesalimentacion/generar/1', $this->payload())->assertStatus(503)
            ->assertJsonPath('message', 'Alimentacion pendiente de migraciones aprobadas.');
        $this->getJson('/api/alimentos')->assertOk()->assertJsonCount(15, 'data');
        $this->assertSame($antes, DB::table('evaluaciones_fisicas')->get()->toJson());
    }

    public function test_female_formula_activity_and_full_duration_limits(): void
    {
        DB::table('perfiles_alimentarios')->update(['sexo_calculo' => 'femenino']);
        DB::table('evaluaciones_fisicas')->update(['actividad_diaria' => 'moderadamente_activo']);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload(['duracion_dias' => 14]))
            ->assertCreated()->assertJsonPath('data.calculo.objetivos.calorias', 2668.95)->assertJsonCount(14, 'data.dias');
        DB::table('evaluaciones_fisicas')->update(['fecha_evaluacion' => '2026-06-20']);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload(['duracion_dias' => 14]))->assertUnprocessable();
        $this->assertDatabaseCount('planes_alimentacion', 1);
    }

    public function test_deployment_is_enabled_without_asserting_professional_review(): void
    {
        $settings = require config_path('alimentacion.php');
        $this->assertTrue($settings['habilitado']);
        $this->assertArrayNotHasKey('reglas_revisadas', $settings);
        DB::table('perfiles_alimentarios')->delete();
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())
            ->assertUnprocessable()->assertJsonValidationErrors('evaluacion');
        $this->assertDatabaseCount('planes_alimentacion', 0);
    }

    private function flutterBody(array $overrides = []): array
    {
        return array_replace(['sexo_calculo' => 'masculino', 'embarazo' => false, 'lactancia' => false,
            'requiere_plan_clinico' => false, 'apto_plan_general' => true, 'preferencias' => []], $overrides);
    }

    public function test_reviews_can_be_null_or_old_without_blocking_generation_and_history_is_preserved(): void
    {
        DB::table('perfiles_alimentarios')->update(['revision_profesional' => 'Revision historica', 'revisado_en' => '2020-01-01']);
        foreach ([$this->flutterBody(), $this->flutterBody(['revision_profesional' => null, 'revisado_en' => null])] as $body) {
            $this->putJson('/api/usuarios/1/perfil-alimentario', $body)->assertOk()
                ->assertJsonPath('data.revision_profesional', 'Revision historica')->assertJsonPath('data.revisado_en', '2020-01-01');
        }
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'revision_profesional' => 'Cliente anterior', 'revisado_en' => '2019-01-01']))->assertOk();
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
        DB::table('perfiles_alimentarios')->update(['revision_profesional' => null, 'revisado_en' => null]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()
            ->assertJsonPath('data.calculo.revision_profesional', null)->assertJsonPath('data.calculo.revisado_en', null);
        $this->putJson('/api/usuarios/2/perfil-alimentario', $this->flutterBody())->assertOk()
            ->assertJsonPath('data.revision_profesional', null)->assertJsonPath('data.revisado_en', null);
    }

    public function test_full_catalog_over_200_checkboxes_persists_and_omitted_foods_keep_previous_rejections(): void
    {
        $modelo = Alimento::first()->getAttributes();
        unset($modelo['id']);
        $nuevos = [];
        for ($i = 0; $i < 250; $i++) {
            $nuevos[] = array_replace($modelo, ['nombre' => 'QA catalogo grande '.$i]);
        }
        DB::table('alimentos')->insert($nuevos);
        $preferencias = Alimento::orderBy('id')->get()->map(fn ($a) => ['id_alimentos' => $a->id,
            'tipo' => $a->id % 2 === 0 ? 'rechazado' : 'preferido'])->all();
        $body = $this->flutterBody(['preferencias' => $preferencias]);
        $this->putJson('/api/usuarios/1/perfil-alimentario', $body)->assertOk()->assertJsonCount(265, 'data.preferencias');
        $this->putJson('/api/usuarios/1/perfil-alimentario', $body)->assertOk();
        $saved = $this->getJson('/api/usuarios/1/perfil-alimentario')->assertOk()->json('data.preferencias');
        $this->assertSame($preferencias, array_map(fn ($p) => ['id_alimentos' => $p['id_alimentos'], 'tipo' => $p['tipo']], $saved));
        $this->assertDatabaseCount('preferencias_alimentarias', 265);
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'preferencias' => [['id_alimentos' => 1, 'tipo' => 'rechazado']]]))->assertOk();
        $this->assertDatabaseHas('preferencias_alimentarias', ['id_usuarios' => 1, 'id_alimentos' => 2, 'activo' => 1, 'tipo' => 'rechazado']);
        $this->assertDatabaseMissing('preferencias_alimentarias', ['id_usuarios' => 2]);
    }

    #[DataProvider('invalidCheckboxes')]
    public function test_invalid_checkbox_ids_and_duplicate_rows_are_rejected_without_changes(array $preferencias): void
    {
        $antes = DB::table('perfiles_alimentarios')->get()->toJson();
        $this->put('/api/usuarios/1/perfil-alimentario', $this->flutterBody(['preferencias' => $preferencias]))
            ->assertUnprocessable()->assertJsonStructure(['message', 'errors']);
        $this->assertSame($antes, DB::table('perfiles_alimentarios')->get()->toJson());
        $this->assertDatabaseCount('preferencias_alimentarias', 0);
    }

    public static function invalidCheckboxes(): array
    {
        return [
            [[['id_alimentos' => 999, 'tipo' => 'preferido']]],
            [[['id_alimentos' => 1, 'tipo' => 'preferido'], ['id_alimentos' => 1, 'tipo' => 'rechazado']]],
            [[['id_alimentos' => 1, 'tipo' => 'preferido'], ['id_alimentos' => '01', 'tipo' => 'rechazado']]],
            [[['id_alimentos' => 1.5, 'tipo' => 'preferido']]],
            [[['id_alimentos' => 1, 'tipo' => 'alergia']]],
            [[['tipo' => 'preferido']]],
            [[['id_alimentos' => 1, 'tipo' => 'preferido', 'id_usuarios' => 2]]],
        ];
    }

    public function test_removed_restrictions_accept_only_empty_legacy_arrays(): void
    {
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'alergias' => [], 'intolerancias' => []]))->assertOk()->assertJsonPath('data.restricciones', []);
        foreach (['alergias', 'intolerancias'] as $campo) {
            $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([$campo => [1]]))
                ->assertUnprocessable()->assertJsonValidationErrors($campo);
        }
        Alimento::query()->update(['restricciones_verificadas' => false]);
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
        foreach (['restricciones_alimentarias', 'alimento_restriccion', 'usuario_restriccion_alimentaria'] as $table) {
            $this->assertFalse(Schema::hasTable($table));
        }
    }

    public function test_checkbox_rejections_apply_to_every_meal_and_insufficient_catalog_never_ignores_them(): void
    {
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'preferencias' => [['id_alimentos' => 1, 'tipo' => 'rechazado'], ['id_alimentos' => 2, 'tipo' => 'rechazado']]]))->assertOk();
        $data = $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated()->json('data');
        foreach ($data['dias'] as $dia) {
            foreach ($dia['comidas'] as $comida) {
                $this->assertNotContains(1, array_column($comida['alimentos'], 'id_alimentos'));
                $this->assertNotContains(2, array_column($comida['alimentos'], 'id_alimentos'));
            }
        }
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
            'preferencias' => [['id_alimentos' => 3, 'tipo' => 'rechazado']]]))->assertOk();
        $this->post('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable()
            ->assertJsonValidationErrors('alimentos');
        $this->assertDatabaseCount('planes_alimentacion', 1);
    }

    public function test_profile_changes_are_atomic_and_do_not_leak_debug_information(): void
    {
        config(['app.debug' => true]);
        $antes = DB::table('perfiles_alimentarios')->get()->toJson();
        \App\Models\PreferenciaAlimentaria::saved(function () {
            throw new \RuntimeException('SQL credentials QA do not leak');
        });
        try {
            $this->put('/api/usuarios/1/perfil-alimentario', $this->flutterBody([
                'sexo_calculo' => 'femenino', 'preferencias' => [['id_alimentos' => 1, 'tipo' => 'rechazado']]]))
                ->assertStatus(500)->assertExactJson(['message' => 'No se pudo completar la operacion de alimentacion.',
                    'errors' => ['solicitud' => ['No se pudo completar la operacion de alimentacion.']]]);
            $this->assertSame($antes, DB::table('perfiles_alimentarios')->get()->toJson());
            $this->assertDatabaseCount('preferencias_alimentarias', 0);
        } finally {
            \App\Models\PreferenciaAlimentaria::flushEventListeners();
        }
        $this->get('/api/usuarios/abc/perfil-alimentario')->assertNotFound()->assertJsonStructure(['message', 'errors']);
    }

    public function test_sex_flags_are_coherent_and_clinical_flags_remain_required(): void
    {
        foreach (['embarazo', 'lactancia'] as $flag) {
            $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody([$flag => true]))
                ->assertUnprocessable()->assertJsonValidationErrors($flag);
            $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody(['sexo_calculo' => 'femenino', $flag => true]))->assertOk();
            $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertUnprocessable();
        }
        foreach (['requiere_plan_clinico', 'apto_plan_general'] as $field) {
            $body = $this->flutterBody();
            unset($body[$field]);
            $this->putJson('/api/usuarios/1/perfil-alimentario', $body)->assertUnprocessable()->assertJsonValidationErrors($field);
        }
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody())->assertOk();
        $this->postJson('/api/planesalimentacion/generar/1', $this->payload())->assertCreated();
    }

    public function test_authorization_denies_other_users_and_does_not_confuse_users_with_usuarios(): void
    {
        $this->actuarComo(['id' => 1, 'id_empresas' => 1, 'tipo_usuario' => 'Usuario']);
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertOk();
        $this->putJson('/api/usuarios/1/perfil-alimentario', $this->flutterBody(['id_usuarios' => 2]))->assertOk()->assertJsonPath('data.id_usuarios', 1);
        $this->putJson('/api/usuarios/2/perfil-alimentario', $this->flutterBody())->assertForbidden();
        $this->getJson('/api/usuarios/2/perfil-alimentario')->assertForbidden();
        $this->postJson('/api/planesalimentacion/generar/2', $this->payload())->assertForbidden();
        $this->assertDatabaseMissing('perfiles_alimentarios', ['id_usuarios' => 2]);
        // Un User con el mismo id numerico no es el Usuario 1.
        $this->sinSesion();
        $otroModelo = new \App\Models\User();
        $otroModelo->forceFill(['id' => 1]);
        $this->actingAs($otroModelo);
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertUnauthorized();
        // Entrenador de la misma empresa: seguimiento permitido. De otra empresa: no.
        $this->actuarComo(['id' => 50, 'id_empresas' => 1, 'tipo_usuario' => 'Entrenador']);
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertOk();
        $this->actuarComo(['id' => 51, 'id_empresas' => 99, 'tipo_usuario' => 'Entrenador']);
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertForbidden();
    }

    public function test_anonymous_production_and_invalid_bearer_are_rejected_but_local_testing_remains_available(): void
    {
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertOk();
        $this->sinSesion();
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertUnauthorized();
        $this->withHeader('Authorization', 'Bearer no-verificado')->getJson('/api/usuarios/1/perfil-alimentario')->assertUnauthorized();
        $this->flushHeaders();
        $this->app['env'] = 'production';
        $this->putJson('https://localhost/api/usuarios/1/perfil-alimentario', $this->flutterBody())->assertUnauthorized();
        $this->getJson('https://localhost/api/usuarios/1/perfil-alimentario')->assertUnauthorized();
        $this->postJson('https://localhost/api/planesalimentacion/generar/1', $this->payload())->assertUnauthorized();
        $this->app['env'] = 'testing';
        config(['alimentacion.permitir_sin_sesion_local' => false]);
        $this->getJson('/api/usuarios/1/perfil-alimentario')->assertUnauthorized();
    }

    public function test_nullable_migration_preserves_history_and_refuses_destructive_rollback(): void
    {
        $migration = require database_path('migrations/2026_09_12_120000_make_alimentacion_review_optional.php');
        $antes = DB::table('perfiles_alimentarios')->get()->toJson();
        $migration->down();
        $migration->up();
        $this->assertSame($antes, DB::table('perfiles_alimentarios')->get()->toJson());
        $this->putJson('/api/usuarios/2/perfil-alimentario', $this->flutterBody())->assertOk();
        $this->expectException(\RuntimeException::class);
        $migration->down();
    }

    public function test_unit_conversions_require_verified_equivalences(): void
    {
        $calc = app(CalculadorPorcionesService::class);
        $a = Alimento::findOrFail(1)->toArray();
        $this->assertEquals(150, $calc->nutrientes($a, 150, 'gramos')['calorias']);
        $a['gramos_por_unidad'] = 50;
        $this->assertEquals(100, $calc->nutrientes($a, 2, 'unidad')['calorias']);
        $a['densidad_g_ml'] = 0.8;
        $this->assertEquals(80, $calc->nutrientes($a, 100, 'mililitros')['calorias']);
        $a['base_unidad'] = 'mililitros';
        $this->assertEquals(125, $calc->nutrientes($a, 100, 'gramos')['calorias']);
        $a['densidad_g_ml'] = null;
        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $calc->nutrientes($a, 100, 'gramos');
    }
}

class UsuarioAutenticadoAlimentacionTest extends \App\Models\Usuario implements \Illuminate\Contracts\Auth\Authenticatable
{
    use \Illuminate\Auth\Authenticatable;
}
