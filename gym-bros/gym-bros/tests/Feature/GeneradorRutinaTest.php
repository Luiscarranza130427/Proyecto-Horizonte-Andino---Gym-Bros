<?php

namespace Tests\Feature;

use App\Models\Ejercicio;
use App\Models\EjercicioRutina;
use App\Models\EvaluacionFisica;
use App\Services\Rutina\GeneradorRutinaService;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class GeneradorRutinaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();

        // Never run these migrations against the developer's configured database.
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null, 'cache.default' => 'array', 'session.driver' => 'array']);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());

        foreach ([
            '2026_08_21_224135_create_empresas.php', '2026_08_21_224236_create_usuarios.php',
            '2026_08_21_224244_create_evaluaciones_fisicas.php', '2026_08_21_224253_create_grupos_musculares.php',
            '2026_08_21_224303_create_ejercicios.php', '2026_08_21_224329_create_ejercicios_grupo_muscular.php',
            '2026_08_21_224335_create_rutinas.php', '2026_08_21_224349_create_ejercicios_rutina.php',
            '2026_08_29_170121_create_empresa_ejercicio_table.php',
            '2026_09_02_230717_add_id_usuario_to_evaluaciones_fisicas_table.php',
            '2026_09_09_120000_prepare_routine_generation.php',
            '2026_09_11_120000_create_routine_generation_usage.php',
        ] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        $this->fixtures();
    }

    protected function tearDown(): void
    {
        EjercicioRutina::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function fixtures(): void
    {
        $empresa = ['nombre' => 'QA', 'nombre_gerente' => 'QA', 'telefono' => '999999999',
            'correo' => 'qa@example.test', 'fecha_registro' => '2026-01-01', 'logo' => 'qa.webp',
            'color_1' => '#000000', 'color_2' => '#ffffff'];
        foreach (['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'] as $dia) {
            $empresa['horario_inicio_'.$dia] = 6;
            $empresa['horario_fin_'.$dia] = 22;
        }
        DB::table('empresas')->insert(['id' => 1] + $empresa);
        DB::table('empresas')->insert(['id' => 2] + $empresa);
        DB::table('usuarios')->insert(['id' => 1, 'nombres' => 'Prueba', 'apellidos' => 'QA', 'apodo' => 'qa',
            'genero' => 'Varon', 'correo' => 'qa@example.test', 'password_hash' => 'not-a-real-account',
            'tipo_documento' => 'DNI', 'numero_documento' => '12345678', 'telefono' => '999999999',
            'fecha_registro' => '2026-01-01', 'fecha_nacimiento' => '1996-01-01',
            'tipo_usuario' => 'Usuario', 'id_empresas' => 1]);
        EvaluacionFisica::create(['id_usuarios' => 1, 'nivel_experiencia' => '1a3meses',
            'actividad_diaria' => 'moderadamente_activo', 'objetivo' => 'ganancia_muscular',
            'edad' => 30, 'peso' => 70, 'altura' => 170, 'porcentaje_grasa' => 20, 'masa_muscular' => 30,
            'cintura' => 80, 'pecho' => 90, 'brazo' => 30, 'muslo' => 50, 'cadera' => 90,
            'dias_semana' => 3, 'eleccion_dias' => ['Lunes', 'Miercoles', 'Viernes'],
            'tiempo_sesion_min' => 60, 'restricciones' => 'sin-restricciones', 'fecha_evaluacion' => '2026-01-01']);

        foreach (['pecho', 'espalda', 'hombros', 'biceps', 'triceps', 'cuadriceps', 'isquitiobiales',
            'gluteos', 'pantorrillas', 'abdomen'] as $i => $grupo) {
            $id = $i + 1;
            DB::table('grupos_musculares')->insert(['id' => $id, 'tipo' => $grupo]);
            foreach (['principiante', 'intermedio', 'avanzado'] as $nivel) {
                $ejercicio = Ejercicio::create(['nombre' => $grupo.' '.$nivel, 'tipo' => 'fuerza',
                    'instrucciones' => 'QA', 'nivel' => $nivel, 'equipamiento' => 'mancuernas',
                    'estado' => true, 'imagen_ejercicio' => 'qa.webp', 'id_grupos_musculares' => $id]);
                DB::table('empresa_ejercicio')->insert(['id_empresas' => 1, 'id_ejercicios' => $ejercicio->id]);
                DB::table('ejercicios_grupo_muscular')->insert(['id_ejercicios' => $ejercicio->id, 'id_grupos_musculares' => $id]);
            }
        }
    }

    public function test_monthly_limit_and_real_evaluation_changes(): void
    {
        $this->travelTo(\Carbon\Carbon::parse('2026-09-11 12:00:00'));
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/rutinas/generar/1')->assertCreated();
        }
        $this->getJson('/api/rutinas/generar/1/estado')->assertOk()->assertJsonPath('data.permitido', false);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        $this->assertDatabaseCount('routine_generation_usage', 3);
        EvaluacionFisica::first()->update(['peso' => 71]);
        $this->getJson('/api/rutinas/generar/1/estado')->assertJsonPath('data.permitido', true);
        $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        EvaluacionFisica::first()->update(['peso' => 70]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        $this->travelTo(\Carbon\Carbon::parse('2026-10-01 12:00:00'));
        $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $this->travelBack();
    }

    public function test_session_endpoint_returns_only_requested_day_in_saved_order(): void
    {
        $rutina = app(GeneradorRutinaService::class)->generar(1)['rutina'];
        $other = app(GeneradorRutinaService::class)->generar(1)['rutina'];
        EvaluacionFisica::first()->update(['dias_semana' => 4, 'eleccion_dias' => null,
            'tiempo_sesion_min' => 90, 'objetivo' => 'salud']);
        $before = DB::table('ejercicios_rutina')->orderBy('id')->get()->toJson();
        $expected = $rutina->ejerciciosRutina()->where('dia', 2)->orderBy('id')->pluck('id')->all();

        $response = $this->getJson('/api/usuarios/1/rutinas/'.$rutina->id.'/sesiones/2')->assertOk()
            ->assertJsonPath('data.id_usuarios', 1)->assertJsonPath('data.id_rutinas', $rutina->id)
            ->assertJsonPath('data.dia', 2)
            ->assertJsonPath('data.dias_semana', 3)
            ->assertJsonPath('data.duracion_estimada', $rutina->duracion_estimada)
            ->assertJsonPath('data.objetivo', 'ganancia_muscular');
        $rows = $response->json('data.ejercicios');
        $this->assertSame($expected, array_column($rows, 'id'));
        $this->assertSame(range(1, count($rows)), array_column($rows, 'orden'));
        foreach ($rows as $row) {
            $this->assertSame(2, $row['dia']);
            $this->assertSame($rutina->id, $row['id_rutinas']);
            $this->assertNotSame($other->id, $row['id_rutinas']);
            $this->assertArrayHasKey('nombre', $row['ejercicio']);
            $this->assertArrayHasKey('grupomuscular', $row['ejercicio']);
            $this->assertArrayHasKey('series', $row);
            $this->assertArrayHasKey('descanso_segundos', $row);
        }
        $this->assertSame($before, DB::table('ejercicios_rutina')->orderBy('id')->get()->toJson());
        $this->assertDatabaseCount('rutinas', 2);
    }

    public function test_session_endpoint_handles_first_and_last_day_and_invalid_parameters(): void
    {
        $id = app(GeneradorRutinaService::class)->generar(1)['rutina']->id;
        $this->getJson('/api/usuarios/1/rutinas/'.$id.'/sesiones/1')->assertOk()->assertJsonPath('data.dia', 1);
        $this->getJson('/api/usuarios/1/rutinas/'.$id.'/sesiones/3')->assertOk()->assertJsonPath('data.dia', 3);
        foreach (['0', '-1', '4', 'lunes', '1.5', '999999999999999999999999'] as $dia) {
            $this->getJson('/api/usuarios/1/rutinas/'.$id.'/sesiones/'.$dia)->assertNotFound();
        }
        $this->getJson('/api/usuarios/1/rutinas/999/sesiones/1')->assertNotFound();
        $this->getJson('/api/usuarios/abc/rutinas/'.$id.'/sesiones/1')->assertNotFound();
        $this->getJson('/api/usuarios/1/rutinas/abc/sesiones/1')->assertNotFound();
    }

    public function test_session_endpoint_rejects_a_routine_belonging_to_another_user(): void
    {
        $usuario = \App\Models\Usuario::first()->replicate();
        $usuario->id_empresas = 2;
        $usuario->save();
        $id = app(GeneradorRutinaService::class)->generar(1)['rutina']->id;
        $this->getJson('/api/usuarios/'.$usuario->id.'/rutinas/'.$id.'/sesiones/1')->assertNotFound();
        $this->getJson('/api/usuarios/999/rutinas/'.$id.'/sesiones/1')->assertNotFound();
    }

    public function test_session_endpoint_reports_a_day_without_saved_exercises(): void
    {
        $id = app(GeneradorRutinaService::class)->generar(1)['rutina']->id;
        DB::table('ejercicios_rutina')->where('id_rutinas', $id)->where('dia', 2)->delete();
        $this->getJson('/api/usuarios/1/rutinas/'.$id.'/sesiones/2')->assertNotFound()
            ->assertJsonPath('message', 'No hay ejercicios guardados para esta sesion.');
        $this->assertDatabaseCount('rutinas', 1);
    }

    public static function objetivosYDias(): array
    {
        $cases = [];
        foreach (['ganancia_muscular', 'aumento_fuerza', 'resistencia', 'perdida_peso', 'recomposicion', 'salud'] as $objetivo) {
            foreach ([2, 3, 4, 5, 6] as $dias) {
                $cases[$objetivo.'-'.$dias] = [$objetivo, $dias];
            }
        }
        return $cases;
    }

    #[DataProvider('objetivosYDias')]
    public function test_generates_complete_routines_within_budget(string $objetivo, int $dias): void
    {
        EvaluacionFisica::first()->update(['objetivo' => $objetivo, 'dias_semana' => $dias, 'eleccion_dias' => null]);
        $response = $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $response->assertJsonPath('data.id_usuarios', 1)->assertJsonPath('data.dias_semana', $dias);
        $this->assertCount($dias, $response->json('data.sesiones'));
        foreach ($response->json('data.sesiones') as $sesion) {
            $this->assertLessThanOrEqual(3600, $sesion['duracion_estimada_segundos']);
            $this->assertNotEmpty($sesion['ejercicios']);
            $ids = array_column($sesion['ejercicios'], 'id_ejercicios');
            $this->assertCount(count(array_unique($ids)), $ids);
            $this->assertSame(range(1, count($ids)), array_column($sesion['ejercicios'], 'orden'));
            foreach ($sesion['ejercicios'] as $ejercicio) {
                $this->assertSame('principiante', $ejercicio['ejercicio']['nivel']);
            }
        }
        $this->assertDatabaseCount('rutinas', 1);
        $this->assertDatabaseCount('ejercicios_rutina', count($response->json('data.ejercicios')));
    }

    public static function invalidProfiles(): array
    {
        return [
            'zero days' => ['dias_semana', 0], 'too many days' => ['dias_semana', 7],
            'negative time' => ['tiempo_sesion_min', -1], 'too much time' => ['tiempo_sesion_min', 181],
            'unknown restriction' => ['restricciones', 'desconocida'],
            'restriction' => ['restricciones', 'lesion-reciente'], 'missing restriction' => ['restricciones', ''],
            'ambiguous experience' => ['nivel_experiencia', '4a8anos'],
            'invalid days' => ['eleccion_dias', '["Lunes","Lunes","Viernes"]'],
            'wrong count' => ['eleccion_dias', '["Lunes","Martes"]'],
        ];
    }

    #[DataProvider('invalidProfiles')]
    public function test_rejects_invalid_profiles_without_writes(string $field, mixed $value): void
    {
        // SQLite enum constraints still apply; unsupported enum values are tested at service level below.
        if (in_array($value, ['desconocida', ''], true)) {
            $evaluacion = EvaluacionFisica::first();
            $evaluacion->$field = $value;
            $this->expectException(\Illuminate\Validation\ValidationException::class);
            app(\App\Services\Rutina\AnalizadorEvaluacionService::class)->analizar($evaluacion);
            return;
        }
        DB::table('evaluaciones_fisicas')->update([$field => $value]);
        $error = $value === '["Lunes","Lunes","Viernes"]' ? 'eleccion_dias.0' : $field;
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors($error);
        $this->assertDatabaseCount('rutinas', 0);
        $this->assertDatabaseCount('ejercicios_rutina', 0);
    }

    public function test_unknown_user_and_invalid_route_are_not_found(): void
    {
        $this->postJson('/api/rutinas/generar/999')->assertNotFound();
        $this->postJson('/api/rutinas/generar/abc')->assertNotFound();
        $this->assertDatabaseCount('rutinas', 0);
    }

    public function test_user_without_evaluation_is_rejected(): void
    {
        DB::table('evaluaciones_fisicas')->delete();
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors('evaluacion');
    }

    public function test_disabled_company_or_user_is_rejected(): void
    {
        DB::table('usuarios')->update(['estado' => false]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        DB::table('usuarios')->update(['estado' => true]);
        DB::table('empresas')->where('id', 1)->update(['estado' => false]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        $this->assertDatabaseCount('rutinas', 0);
    }

    public function test_company_availability_and_exercise_and_group_status_are_mandatory(): void
    {
        $id = Ejercicio::where('nombre', 'pecho principiante')->value('id');
        foreach (['empresa_ejercicio', 'ejercicios', 'grupos_musculares'] as $table) {
            $query = DB::table($table)->where($table === 'empresa_ejercicio' ? 'id_ejercicios' : 'id', $table === 'grupos_musculares' ? 1 : $id);
            $query->update(['estado' => false]);
            $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
            $query->update(['estado' => true]);
        }
        DB::table('empresa_ejercicio')->where('id_ejercicios', $id)->update(['id_empresas' => 2]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        $this->assertDatabaseCount('rutinas', 0);
    }

    public function test_latest_evaluation_uses_date_then_id_not_insertion_order(): void
    {
        $old = EvaluacionFisica::first()->replicate();
        $old->fecha_evaluacion = '2025-01-01';
        $old->restricciones = 'lesion-reciente';
        $old->save();
        $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $latest = EvaluacionFisica::first()->replicate();
        $latest->restricciones = 'lesion-reciente';
        $latest->save();
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
    }

    public function test_duration_limit_can_reduce_volume_but_never_overflow(): void
    {
        EvaluacionFisica::first()->update(['tiempo_sesion_min' => 30, 'objetivo' => 'aumento_fuerza']);
        $result = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data.sesiones');
        foreach ($result as $session) {
            $this->assertLessThanOrEqual(1800, $session['duracion_estimada_segundos']);
        }
        EvaluacionFisica::first()->update(['tiempo_sesion_min' => 10]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors('tiempo_sesion_min');
        $this->assertDatabaseCount('rutinas', 1);
    }

    public function test_generation_is_deterministic_and_preserves_previous_routine(): void
    {
        $first = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data');
        $second = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data');
        $this->assertSame(array_column($first['ejercicios'], 'id_ejercicios'), array_column($second['ejercicios'], 'id_ejercicios'));
        $this->assertDatabaseHas('rutinas', ['id' => $first['id'], 'estado' => 1]);
        $this->assertDatabaseCount('rutinas', 2);
    }

    public function test_failure_during_details_rolls_back_every_insert(): void
    {
        $counter = 0;
        EjercicioRutina::creating(function () use (&$counter) {
            if (++$counter === 2) {
                throw new \RuntimeException('Simulated write failure');
            }
        });
        try {
            app(GeneradorRutinaService::class)->generar(1);
            $this->fail('Expected a write failure.');
        } catch (\RuntimeException $e) {
            $this->assertSame('Simulated write failure', $e->getMessage());
        }
        $this->assertDatabaseCount('rutinas', 0);
        $this->assertDatabaseCount('ejercicios_rutina', 0);
    }

    public function test_existing_routine_endpoint_still_works(): void
    {
        $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $this->getJson('/api/rutinas')->assertOk()->assertJsonPath('data.0.id_usuarios', 1);
    }

    public function test_legacy_day_string_is_read_without_losing_it(): void
    {
        DB::table('evaluaciones_fisicas')->update(['eleccion_dias' => 'Lunes']);
        $this->assertSame(['Lunes'], EvaluacionFisica::first()->eleccion_dias);
        $this->getJson('/api/evaluacionesfisicas')->assertOk()->assertJsonPath('data.0.eleccion_dias', 'Lunes');
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors('eleccion_dias');
    }

    public function test_new_migration_backfills_existing_pivot_and_preserves_evaluation(): void
    {
        $migration = require database_path('migrations/2026_09_09_120000_prepare_routine_generation.php');
        DB::table('evaluaciones_fisicas')->update(['eleccion_dias' => 'Lunes', 'nivel_experiencia' => '1a3meses']);
        $migration->down();
        $migration->up();
        $this->assertDatabaseHas('ejercicios_grupo_muscular', ['id_ejercicios' => 1, 'id_grupos_musculares' => 1]);
        $this->assertDatabaseHas('evaluaciones_fisicas', ['id_usuarios' => 1, 'eleccion_dias' => 'Lunes']);
        $this->assertDatabaseCount('ejercicios', 30);
    }

    public function test_rollback_refuses_to_discard_multiple_days(): void
    {
        $migration = require database_path('migrations/2026_09_09_120000_prepare_routine_generation.php');
        try {
            $migration->down();
            $this->fail('Expected a non-lossy rollback guard.');
        } catch (\RuntimeException $e) {
            $this->assertStringContainsString('Rollback cancelado', $e->getMessage());
        }
        $this->assertSame(['Lunes', 'Miercoles', 'Viernes'], EvaluacionFisica::first()->eleccion_dias);
        $this->assertDatabaseHas('ejercicios_grupo_muscular', ['id_ejercicios' => 1, 'id_grupos_musculares' => 1]);
    }

    public function test_higher_levels_are_ranked_and_unknown_profiles_rejected(): void
    {
        foreach (['1ano' => 'intermedio', '2anos' => 'avanzado'] as $experience => $level) {
            EvaluacionFisica::first()->update(['nivel_experiencia' => $experience]);
            $first = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data.ejercicios.0');
            $this->assertSame($level, $first['ejercicio']['nivel']);
        }
        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $evaluation = EvaluacionFisica::first();
        $evaluation->objetivo = 'inventado';
        app(\App\Services\Rutina\AnalizadorEvaluacionService::class)->analizar($evaluation);
    }

    public function test_secondary_muscle_relation_is_used_and_duplicates_are_not_selected(): void
    {
        DB::table('ejercicios')->where('nombre', 'pecho principiante')->update(['estado' => false]);
        $candidate = Ejercicio::where('nombre', 'triceps principiante')->first();
        DB::table('ejercicios_grupo_muscular')->insert(['id_ejercicios' => $candidate->id, 'id_grupos_musculares' => 1]);
        $response = $this->postJson('/api/rutinas/generar/1')->assertCreated();
        $this->assertSame($candidate->id, $response->json('data.ejercicios.0.id_ejercicios'));
    }

    public function test_cardio_is_optional_and_has_timed_not_repetition_volume(): void
    {
        $cardio = Ejercicio::create(['nombre' => 'Cardio QA', 'tipo' => 'cardio', 'instrucciones' => 'QA',
            'nivel' => 'principiante', 'equipamiento' => 'bicicleta', 'estado' => true,
            'imagen_ejercicio' => 'qa.webp', 'id_grupos_musculares' => 6]);
        DB::table('empresa_ejercicio')->insert(['id_empresas' => 1, 'id_ejercicios' => $cardio->id]);
        EvaluacionFisica::first()->update(['objetivo' => 'perdida_peso']);
        $data = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data');
        $timed = collect($data['ejercicios'])->where('id_ejercicios', $cardio->id);
        $this->assertCount(3, $timed);
        foreach ($timed as $row) {
            $this->assertSame(0, $row['repeticiones']);
            $this->assertSame(300, $row['tiempo_segundos']);
        }
        EvaluacionFisica::first()->update(['tiempo_sesion_min' => 30]);
        $data = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data');
        $this->assertCount(0, collect($data['ejercicios'])->where('id_ejercicios', $cardio->id));
        $this->assertStringContainsString('Se omitio el cardio', implode(' ', $data['advertencias']));
    }

    public function test_consecutive_full_body_days_and_future_evaluation_are_rejected(): void
    {
        EvaluacionFisica::first()->update(['eleccion_dias' => ['Lunes', 'Martes', 'Miercoles']]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors('eleccion_dias');
        EvaluacionFisica::first()->update(['eleccion_dias' => null, 'fecha_evaluacion' => today()->addDay()]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable()->assertJsonValidationErrors('fecha_evaluacion');
    }

    public function test_client_cannot_override_company_or_profile_through_request_body(): void
    {
        $data = $this->postJson('/api/rutinas/generar/1', ['id_empresas' => 2, 'id_usuarios' => 999,
            'nivel' => 'avanzado', 'dias_semana' => 6, 'restricciones' => 'sin-restricciones'])->assertCreated()->json('data');
        $this->assertSame(1, $data['id_usuarios']);
        $this->assertSame(3, $data['dias_semana']);
        $this->assertSame('principiante', $data['ejercicios'][0]['ejercicio']['nivel']);
    }

    public function test_series_and_time_are_consistent_at_exact_budget_boundary(): void
    {
        EvaluacionFisica::first()->update(['objetivo' => 'ganancia_muscular', 'tiempo_sesion_min' => 26]);
        // Six exercises: 6*(2*10*4 + 90) + 5*45 + 300 = 1545 seconds.
        $data = $this->postJson('/api/rutinas/generar/1')->assertCreated()->json('data');
        $this->assertSame(26, $data['duracion_estimada']);
        $this->assertSame(1545, $data['sesiones'][0]['duracion_estimada_segundos']);
        $this->assertSame(170, $data['ejercicios'][0]['tiempo_segundos']);
        EvaluacionFisica::first()->update(['tiempo_sesion_min' => 25]);
        $this->postJson('/api/rutinas/generar/1')->assertUnprocessable();
        $this->assertDatabaseCount('rutinas', 1);
    }

    public function test_evaluation_store_validation_handles_invalid_days_input_without_exception(): void
    {
        $request = \App\Http\Requests\StoreEvaluacionFisicaRequest::create('/', 'POST', ['dias_semana' => ['invalid']]);
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), $request->rules());
        $this->assertTrue($validator->fails());
        $this->assertTrue($validator->errors()->has('dias_semana'));
    }

    public function test_rollback_preserves_secondary_muscle_associations(): void
    {
        DB::table('evaluaciones_fisicas')->update(['eleccion_dias' => 'Lunes']);
        DB::table('ejercicios_grupo_muscular')->insert(['id_ejercicios' => 1, 'id_grupos_musculares' => 2]);
        $migration = require database_path('migrations/2026_09_09_120000_prepare_routine_generation.php');
        try {
            $migration->down();
            $this->fail('Expected rollback to preserve secondary muscles.');
        } catch (\RuntimeException $e) {
            $this->assertStringContainsString('musculos secundarios', $e->getMessage());
        }
        $this->assertDatabaseHas('ejercicios_grupo_muscular', ['id_ejercicios' => 1, 'id_grupos_musculares' => 2]);
    }
}
