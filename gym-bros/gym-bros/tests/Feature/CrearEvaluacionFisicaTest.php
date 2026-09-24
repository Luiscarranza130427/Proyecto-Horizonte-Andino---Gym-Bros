<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class CrearEvaluacionFisicaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());

        Schema::create('usuarios', fn (Blueprint $table) => $table->id());
        Schema::create('grupos_musculares', fn (Blueprint $table) => $table->id());
        Schema::create('ejercicios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_grupos_musculares')->constrained('grupos_musculares');
        });
        // Use the actual evaluation migrations so required columns and enums are exercised.
        foreach (['2026_08_21_224244_create_evaluaciones_fisicas.php',
            '2026_08_21_224329_create_ejercicios_grupo_muscular.php',
            '2026_09_02_230717_add_id_usuario_to_evaluaciones_fisicas_table.php',
            '2026_09_09_120000_prepare_routine_generation.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        DB::table('usuarios')->insert([['id' => 1], ['id' => 2]]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    public function test_after_height_migration_only_new_explicit_heights_are_marked_as_cm(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload(['altura' => 1.76]))->assertCreated();
        (require database_path('migrations/2026_09_12_000001_add_altura_unidad_to_evaluaciones_fisicas.php'))->up();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['altura' => 1.76, 'altura_unidad' => null]);
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['peso' => 75])->assertOk();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['altura' => 1.76, 'altura_unidad' => null]);
        foreach ([1.76, 29, 251, 999.99] as $altura) {
            $this->postJson('/api/usuarios/1/evaluaciones', $this->payload(['altura' => $altura]))
                ->assertUnprocessable()->assertJsonValidationErrors('altura');
            $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['altura' => $altura])->assertUnprocessable();
        }
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['altura' => 176])->assertOk();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['altura' => 176, 'altura_unidad' => 'cm']);
        $this->postJson('/api/usuarios/2/evaluaciones', $this->payload(['altura' => 165]))->assertCreated();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['id_usuarios' => 2, 'altura' => 165, 'altura_unidad' => 'cm']);
    }

    private function payload(array $overrides = []): array
    {
        return array_replace([
            'nivel_experiencia' => '4a8meses', 'actividad_diaria' => 'moderadamente_activo',
            'objetivo' => 'ganancia_muscular', 'edad' => 30, 'peso' => 72.35, 'altura' => 170,
            'porcentaje_grasa' => 18.75, 'masa_muscular' => 30, 'cintura' => 80, 'pecho' => 90,
            'brazo' => 30, 'muslo' => 50, 'cadera' => 90, 'dias_semana' => 3,
            'eleccion_dias' => ['Lunes', 'Miercoles', 'Viernes'], 'tiempo_sesion_min' => 60,
            'restricciones' => 'sin-restricciones', 'fecha_evaluacion' => '2026-09-01',
        ], $overrides);
    }

    public function test_creates_evaluation_and_preserves_history_and_existing_get_endpoints(): void
    {
        $first = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated()->json('data');
        $before = DB::table('evaluaciones_fisicas')->where('id', $first['id'])->first();
        $response = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload([
            'fecha_evaluacion' => '2026-09-09', 'peso' => 71.25,
        ]))->assertCreated()->assertJsonPath('data.id_usuarios', 1)
            ->assertJsonPath('data.eleccion_dias', ['Lunes', 'Miercoles', 'Viernes']);
        $second = $response->json('data.id');
        $this->assertNotSame($first['id'], $second);
        $this->assertEquals($before, DB::table('evaluaciones_fisicas')->where('id', $first['id'])->first());
        $this->assertDatabaseCount('evaluaciones_fisicas', 2);
        $this->assertDatabaseHas('evaluaciones_fisicas', ['id' => $second, 'id_usuarios' => 1, 'peso' => 71.25]);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()->assertJsonPath('data.id_evaluacion', $second);
        $this->getJson('/api/usuarios/1/evaluaciones/peso-grasa')->assertOk()->assertJsonPath('data.peso', 71.25);
    }

    public function test_route_user_is_authoritative_and_unvalidated_fields_are_ignored(): void
    {
        $response = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload([
            'id_usuarios' => 2, 'id' => 99, 'created_at' => '2000-01-01', 'id_empresas' => 2,
        ]))->assertCreated()->assertJsonPath('data.id_usuarios', 1);
        $this->assertNotSame(99, $response->json('data.id'));
        $this->assertDatabaseMissing('evaluaciones_fisicas', ['id_usuarios' => 2]);
    }

    public function test_optional_days_and_known_restrictions_can_be_recorded(): void
    {
        $payload = $this->payload(['restricciones' => 'lesion-reciente']);
        unset($payload['eleccion_dias']);
        $this->postJson('/api/usuarios/1/evaluaciones', $payload)->assertCreated()
            ->assertJsonPath('data.eleccion_dias', null)->assertJsonPath('data.restricciones', 'lesion-reciente');
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload(['eleccion_dias' => null]))->assertCreated();
        $this->assertDatabaseCount('evaluaciones_fisicas', 2);
    }

    public function test_decimal_limits_and_zero_body_fat_are_preserved(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload([
            'peso' => 9999.99, 'altura' => 999.99, 'porcentaje_grasa' => 0,
        ]))->assertCreated();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['peso' => 9999.99, 'altura' => 999.99, 'porcentaje_grasa' => 0]);
    }

    public function test_missing_required_fields_return_json_even_without_accept_header(): void
    {
        $this->post('/api/usuarios/1/evaluaciones', [])->assertUnprocessable()
            ->assertJsonValidationErrors(['peso', 'altura', 'objetivo', 'edad', 'fecha_evaluacion']);
        $this->assertDatabaseCount('evaluaciones_fisicas', 0);
    }

    public function test_update_changes_only_latest_evaluation_and_keeps_other_fields_and_users(): void
    {
        $latest = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload(['fecha_evaluacion' => '2026-09-09']))->assertCreated()->json('data.id');
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        $this->postJson('/api/usuarios/2/evaluaciones', $this->payload(['fecha_evaluacion' => '2026-09-09']))->assertCreated();
        $others = DB::table('evaluaciones_fisicas')->where('id', '<>', $latest)->orderBy('id')->get()->toJson();
        $before = (array) DB::table('evaluaciones_fisicas')->where('id', $latest)->first();
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['peso' => 71.25, 'porcentaje_grasa' => 17.5])
            ->assertOk()->assertJsonPath('data.id', $latest)->assertJsonPath('data.id_usuarios', 1);
        $after = (array) DB::table('evaluaciones_fisicas')->where('id', $latest)->first();
        $this->assertEquals(71.25, $after['peso']);
        $this->assertEquals(17.5, $after['porcentaje_grasa']);
        foreach (['peso', 'porcentaje_grasa', 'updated_at'] as $field) {
            unset($before[$field], $after[$field]);
        }
        $this->assertSame($before, $after);
        $this->assertSame($others, DB::table('evaluaciones_fisicas')->where('id', '<>', $latest)->orderBy('id')->get()->toJson());
        $this->assertDatabaseCount('evaluaciones_fisicas', 3);
        $this->getJson('/api/usuarios/1/evaluaciones/peso-grasa')->assertOk()->assertJsonPath('data.peso', 71.25);
    }

    public function test_update_same_date_chooses_highest_id_and_cannot_reassign_user(): void
    {
        $first = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated()->json('data.id');
        $last = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated()->json('data.id');
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['objetivo' => 'salud', 'id_usuarios' => 2, 'id' => $first])
            ->assertOk()->assertJsonPath('data.id', $last)->assertJsonPath('data.id_usuarios', 1)
            ->assertJsonPath('data.objetivo', 'salud');
        $this->assertDatabaseHas('evaluaciones_fisicas', ['id' => $first, 'objetivo' => 'ganancia_muscular']);
        $this->assertDatabaseMissing('evaluaciones_fisicas', ['id_usuarios' => 2]);
    }

    public function test_update_days_validates_against_saved_values_and_allows_null_calendar(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        $before = DB::table('evaluaciones_fisicas')->get()->toJson();
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['dias_semana' => 4, 'peso' => 80])
            ->assertUnprocessable()->assertJsonValidationErrors('eleccion_dias');
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['eleccion_dias' => ['Lunes', 'Jueves']])
            ->assertUnprocessable()->assertJsonValidationErrors('eleccion_dias');
        $this->assertSame($before, DB::table('evaluaciones_fisicas')->get()->toJson());
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['eleccion_dias' => ['Martes', 'Jueves', 'Sabado']])
            ->assertOk()->assertJsonPath('data.dias_semana', 3);
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['dias_semana' => 4,
            'eleccion_dias' => ['Lunes', 'Martes', 'Jueves', 'Viernes']])->assertOk()->assertJsonPath('data.dias_semana', 4);
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['dias_semana' => 2, 'eleccion_dias' => null])
            ->assertOk()->assertJsonPath('data.eleccion_dias', null);
        $this->assertDatabaseCount('evaluaciones_fisicas', 1);
    }

    public function test_update_can_change_measurements_without_rewriting_legacy_days(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        DB::table('evaluaciones_fisicas')->update(['eleccion_dias' => 'Lunes']);
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['peso' => 73])->assertOk();
        $this->assertDatabaseHas('evaluaciones_fisicas', ['peso' => 73, 'eleccion_dias' => 'Lunes']);
    }

    public function test_update_rejects_empty_payload_and_null_required_values_without_accept_header(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        $before = DB::table('evaluaciones_fisicas')->get()->toJson();
        foreach ([[], ['id_usuarios' => 2], ['campo_desconocido' => 1], ['peso' => null], ['objetivo' => null]] as $body) {
            $this->put('/api/usuarios/1/evaluaciones/ultima', $body)->assertUnprocessable()->assertJsonStructure(['errors']);
        }
        $this->assertSame($before, DB::table('evaluaciones_fisicas')->get()->toJson());
    }

    public function test_update_missing_user_or_evaluation_returns_404_without_insert(): void
    {
        $this->postJson('/api/usuarios/2/evaluaciones', $this->payload())->assertCreated();
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['peso' => 70])->assertNotFound()
            ->assertJsonPath('message', 'El usuario no tiene evaluaciones fisicas registradas.');
        foreach (['999', '0', '-1', 'abc', '1.5'] as $id) {
            $this->putJson('/api/usuarios/'.$id.'/evaluaciones/ultima', ['peso' => 70])->assertNotFound();
        }
        $this->assertDatabaseCount('evaluaciones_fisicas', 1);
    }

    public function test_update_date_changes_the_selected_record_not_the_new_latest(): void
    {
        $first = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated()->json('data.id');
        $last = $this->postJson('/api/usuarios/1/evaluaciones', $this->payload(['fecha_evaluacion' => '2026-09-09']))->assertCreated()->json('data.id');
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['fecha_evaluacion' => '2026-08-01'])->assertOk()->assertJsonPath('data.id', $last);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()->assertJsonPath('data.id_evaluacion', $first);
        $this->assertDatabaseCount('evaluaciones_fisicas', 2);
    }

    #[DataProvider('invalidPayloads')]
    public function test_update_invalid_values_leave_all_data_unchanged(string $field, mixed $value, string $error): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        $before = DB::table('evaluaciones_fisicas')->get()->toJson();
        $this->putJson('/api/usuarios/1/evaluaciones/ultima', [$field => $value])->assertUnprocessable()->assertJsonValidationErrors($error);
        $this->assertSame($before, DB::table('evaluaciones_fisicas')->get()->toJson());
    }

    public function test_update_rolls_back_when_an_error_occurs_after_saving(): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload())->assertCreated();
        $before = DB::table('evaluaciones_fisicas')->get()->toJson();
        \App\Models\EvaluacionFisica::updated(function () {
            throw new \RuntimeException('Simulated update failure');
        });
        try {
            $this->putJson('/api/usuarios/1/evaluaciones/ultima', ['peso' => 80])->assertStatus(500);
            $this->assertSame($before, DB::table('evaluaciones_fisicas')->get()->toJson());
        } finally {
            \App\Models\EvaluacionFisica::flushEventListeners();
        }
    }

    public static function invalidPayloads(): array
    {
        return [
            ['objetivo', 'inventado', 'objetivo'], ['nivel_experiencia', '4a8anos', 'nivel_experiencia'],
            ['actividad_diaria', 'inventada', 'actividad_diaria'], ['restricciones', 'inventada', 'restricciones'],
            ['peso', -1, 'peso'], ['peso', 10000, 'peso'], ['peso', 72.355, 'peso'],
            ['altura', 1000, 'altura'], ['altura', 0, 'altura'], ['peso', ['invalid'], 'peso'],
            ['porcentaje_grasa', 101, 'porcentaje_grasa'], ['porcentaje_grasa', -1, 'porcentaje_grasa'],
            ['masa_muscular', -1, 'masa_muscular'], ['cintura', -1, 'cintura'],
            ['edad', 0, 'edad'], ['edad', 2147483648, 'edad'], ['edad', 30.5, 'edad'],
            ['dias_semana', 0, 'dias_semana'], ['dias_semana', 7, 'dias_semana'],
            ['dias_semana', ['invalid'], 'dias_semana'],
            ['eleccion_dias', ['Lunes', 'Lunes', 'Viernes'], 'eleccion_dias.0'],
            ['eleccion_dias', ['Lunes'], 'eleccion_dias'], ['eleccion_dias', 'Lunes', 'eleccion_dias'],
            ['eleccion_dias', ['Lunes', 'Martes', 'Ninguno'], 'eleccion_dias.2'],
            ['tiempo_sesion_min', 0, 'tiempo_sesion_min'], ['tiempo_sesion_min', 181, 'tiempo_sesion_min'],
            ['fecha_evaluacion', '2026-02-30', 'fecha_evaluacion'], ['fecha_evaluacion', '2999-01-01', 'fecha_evaluacion'],
        ];
    }

    #[DataProvider('invalidPayloads')]
    public function test_invalid_data_never_creates_a_record(string $field, mixed $value, string $error): void
    {
        $this->postJson('/api/usuarios/1/evaluaciones', $this->payload([$field => $value]))
            ->assertUnprocessable()->assertJsonValidationErrors($error);
        $this->assertDatabaseCount('evaluaciones_fisicas', 0);
    }

    public function test_missing_or_invalid_user_is_not_found(): void
    {
        foreach (['999', '0', '-1', 'abc', '1.5'] as $id) {
            $this->postJson('/api/usuarios/'.$id.'/evaluaciones', $this->payload())->assertNotFound();
        }
        $this->assertDatabaseCount('evaluaciones_fisicas', 0);
    }
}
