<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PerfilEvaluacionUsuarioTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());

        // Only the columns needed by this read endpoint, isolated from local MySQL.
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
        });
        Schema::create('evaluaciones_fisicas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_usuarios')->constrained('usuarios');
            $table->string('objetivo');
            $table->string('nivel_experiencia');
            $table->string('actividad_diaria');
            $table->integer('dias_semana');
            $table->text('eleccion_dias')->nullable();
            $table->integer('tiempo_sesion_min');
            $table->string('restricciones');
            $table->date('fecha_evaluacion');
        });
        DB::table('usuarios')->insert([['id' => 1], ['id' => 2]]);
    }

    protected function tearDown(): void
    {
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function evaluacion(array $overrides = []): int
    {
        return DB::table('evaluaciones_fisicas')->insertGetId(array_replace([
            'id_usuarios' => 1, 'objetivo' => 'ganancia_muscular', 'nivel_experiencia' => '1a3meses',
            'actividad_diaria' => 'moderadamente_activo', 'dias_semana' => 3,
            'eleccion_dias' => '["Lunes","Miercoles","Viernes"]', 'tiempo_sesion_min' => 60,
            'restricciones' => 'sin-restricciones', 'fecha_evaluacion' => '2026-09-09',
        ], $overrides));
    }

    public function test_returns_latest_profile_for_requested_user_without_modifying_it(): void
    {
        $id = $this->evaluacion();
        $this->evaluacion(['fecha_evaluacion' => '2026-09-01', 'objetivo' => 'salud']);
        $this->evaluacion(['id_usuarios' => 2, 'objetivo' => 'aumento_fuerza']);
        $before = DB::table('evaluaciones_fisicas')->orderBy('id')->get()->toJson();

        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()->assertExactJson([
            'data' => ['id_usuarios' => 1, 'id_evaluacion' => $id, 'fecha_evaluacion' => '2026-09-09',
                'objetivo' => 'ganancia_muscular', 'nivel_experiencia' => '1a3meses',
                'actividad_diaria' => 'moderadamente_activo', 'dias_semana' => 3,
                'eleccion_dias' => ['Lunes', 'Miercoles', 'Viernes'], 'tiempo_sesion_min' => 60,
                'restricciones' => 'sin-restricciones'],
        ]);
        $this->assertSame($before, DB::table('evaluaciones_fisicas')->orderBy('id')->get()->toJson());
    }

    public function test_same_date_uses_highest_id_and_returns_restrictions_without_filtering(): void
    {
        $this->evaluacion();
        $id = $this->evaluacion(['objetivo' => 'salud', 'restricciones' => 'lesion-reciente']);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()
            ->assertJsonPath('data.id_evaluacion', $id)->assertJsonPath('data.objetivo', 'salud')
            ->assertJsonPath('data.restricciones', 'lesion-reciente');
    }

    public function test_preserves_unspecified_days_and_reads_legacy_single_day(): void
    {
        $this->evaluacion(['eleccion_dias' => null]);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()->assertJsonPath('data.eleccion_dias', null);
        DB::table('evaluaciones_fisicas')->update(['eleccion_dias' => 'Lunes']);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertOk()->assertJsonPath('data.eleccion_dias', ['Lunes']);
        $this->assertDatabaseHas('evaluaciones_fisicas', ['eleccion_dias' => 'Lunes']);
    }

    public function test_no_evaluation_does_not_return_another_users_profile(): void
    {
        $this->evaluacion(['id_usuarios' => 2]);
        $this->getJson('/api/usuarios/1/evaluaciones/perfil')->assertNotFound()
            ->assertJsonPath('message', 'El usuario no tiene evaluaciones fisicas registradas.');
    }

    public function test_nonexistent_user_and_invalid_identifiers_are_rejected(): void
    {
        foreach (['999', '0', '-1', 'abc', '1.5'] as $id) {
            $this->getJson('/api/usuarios/'.$id.'/evaluaciones/perfil')->assertNotFound();
        }
    }
}
