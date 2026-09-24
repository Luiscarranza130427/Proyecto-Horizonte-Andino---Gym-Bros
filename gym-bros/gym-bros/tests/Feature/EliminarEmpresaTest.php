<?php

namespace Tests\Feature;

use App\Models\Empresa;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class EliminarEmpresaTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        DB::statement('PRAGMA foreign_keys = ON');
        Storage::fake('public');
        Storage::disk('public')->put('empresas/compartido.png', 'keep');
        foreach (['empresas', 'planes', 'alimentos', 'ejercicios'] as $table) {
            Schema::create($table, fn (Blueprint $t) => $t->id());
        }
        Schema::create('usuarios', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_empresas')->constrained('empresas')->cascadeOnDelete();
        });
        foreach (['evaluaciones_fisicas', 'rutinas', 'preferencias_alimentarias', 'progresos', 'perfiles_alimentarios'] as $table) {
            Schema::create($table, function (Blueprint $t) {
                $t->id(); $t->foreignId('id_usuarios')->constrained('usuarios')->cascadeOnDelete();
            });
        }
        Schema::create('planes_alimentacion', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_usuarios')->constrained('usuarios')->cascadeOnDelete();
            $t->foreignId('id_evaluaciones_fisicas')->nullable()->constrained('evaluaciones_fisicas')->nullOnDelete();
        });
        Schema::create('sensaciones', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_usuarios')->constrained('usuarios')->cascadeOnDelete();
            $t->foreignId('id_rutinas')->constrained('rutinas')->cascadeOnDelete();
        });
        foreach (['comidas' => ['id_planes_alimentacion', 'planes_alimentacion'],
            'comida_alimentos' => ['id_comidas', 'comidas'], 'ejercicios_rutina' => ['id_rutinas', 'rutinas'],
            'empresa_ejercicio' => ['id_empresas', 'empresas']] as $table => [$column, $parent]) {
            Schema::create($table, function (Blueprint $t) use ($column, $parent) {
                $t->id(); $t->foreignId($column)->constrained($parent)->cascadeOnDelete();
            });
        }
        Schema::create('suscripciones', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_empresas')->constrained('empresas')->restrictOnDelete();
        });
        Schema::create('pagos', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_empresas')->constrained('empresas')->cascadeOnDelete();
            $t->foreignId('id_suscripciones')->constrained('suscripciones')->cascadeOnDelete();
        });
        Schema::create('historial_cambios', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_empresas')->constrained('empresas')->restrictOnDelete();
            $t->foreignId('id_usuarios')->constrained('usuarios')->restrictOnDelete();
        });
        Schema::create('notificaciones', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_empresas')->nullable()->constrained('empresas')->nullOnDelete();
            $t->foreignId('id_usuarios')->nullable()->constrained('usuarios')->nullOnDelete();
        });
        (require database_path('migrations/2026_09_11_120000_create_routine_generation_usage.php'))->up();
        foreach ([1, 2] as $id) {
            DB::table('empresas')->insert(['id' => $id]);
            DB::table('usuarios')->insert(['id' => $id, 'id_empresas' => $id]);
            foreach (['evaluaciones_fisicas', 'rutinas', 'preferencias_alimentarias', 'progresos', 'perfiles_alimentarios'] as $table) {
                DB::table($table)->insert(['id' => $id, 'id_usuarios' => $id]);
            }
            DB::table('planes_alimentacion')->insert(['id' => $id, 'id_usuarios' => $id, 'id_evaluaciones_fisicas' => $id]);
            DB::table('sensaciones')->insert(['id' => $id, 'id_usuarios' => $id, 'id_rutinas' => $id]);
            foreach (['comidas' => 'id_planes_alimentacion', 'comida_alimentos' => 'id_comidas',
                'ejercicios_rutina' => 'id_rutinas', 'empresa_ejercicio' => 'id_empresas', 'suscripciones' => 'id_empresas'] as $table => $col) {
                DB::table($table)->insert(['id' => $id, $col => $id]);
            }
            DB::table('pagos')->insert(['id' => $id, 'id_empresas' => $id, 'id_suscripciones' => $id]);
            foreach (['historial_cambios', 'notificaciones'] as $table) {
                DB::table($table)->insert(['id' => $id, 'id_empresas' => $id, 'id_usuarios' => $id]);
            }
            DB::table('routine_generation_usage')->insert(['id' => $id, 'user_id' => $id, 'routine_id' => $id,
                'evaluation_hash' => str_repeat('a', 64), 'created_at' => now()]);
        }
        DB::table('usuarios')->insert(['id' => 3, 'id_empresas' => 1]);
        DB::table('empresas')->insert(['id' => 3]);
        DB::table('notificaciones')->insert(['id' => 3, 'id_empresas' => null, 'id_usuarios' => 1]);
        DB::table('notificaciones')->insert(['id' => 4, 'id_empresas' => null, 'id_usuarios' => null]);
        foreach (['planes', 'alimentos', 'ejercicios'] as $table) { DB::table($table)->insert(['id' => 1]); }
    }

    protected function tearDown(): void
    {
        Empresa::flushEventListeners();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function snapshot(): array
    {
        $rows = [];
        foreach (Schema::getTableListing() as $table) { $rows[$table] = DB::table($table)->orderBy('id')->get()->toJson(); }
        return $rows;
    }

    public function test_elimina_empresa_y_cascada_sin_afectar_otra_empresa_catalogos_o_archivos(): void
    {
        $this->deleteJson('/api/empresas/1', ['confirmar_eliminacion' => true, 'id_empresa' => 2])->assertOk()
            ->assertJsonPath('data.id_empresa', 1)->assertJsonPath('data.usuarios_eliminados', 2);
        foreach (['empresas', 'usuarios', 'evaluaciones_fisicas', 'rutinas', 'preferencias_alimentarias', 'progresos',
            'perfiles_alimentarios', 'planes_alimentacion', 'sensaciones', 'comidas', 'comida_alimentos',
            'ejercicios_rutina', 'empresa_ejercicio', 'suscripciones', 'pagos', 'historial_cambios', 'routine_generation_usage'] as $table) {
            $this->assertDatabaseMissing($table, ['id' => 1]);
            $this->assertDatabaseHas($table, ['id' => 2]);
        }
        $this->assertDatabaseMissing('usuarios', ['id' => 3]);
        $this->assertDatabaseMissing('notificaciones', ['id' => 1]);
        $this->assertDatabaseMissing('notificaciones', ['id' => 3]);
        $this->assertDatabaseHas('notificaciones', ['id' => 2]);
        $this->assertDatabaseHas('notificaciones', ['id' => 4]);
        foreach (['planes', 'alimentos', 'ejercicios'] as $table) { $this->assertDatabaseCount($table, 1); }
        Storage::disk('public')->assertExists('empresas/compartido.png');
        $this->deleteJson('/api/empresas/1', ['confirmar_eliminacion' => true])->assertNotFound();
    }

    public function test_requiere_confirmacion_y_no_elimina_por_get(): void
    {
        $before = $this->snapshot();
        foreach ([[], ['confirmar_eliminacion' => false], ['confirmar_eliminacion' => 'no']] as $body) {
            $this->delete('/api/empresas/1', $body)->assertUnprocessable()->assertJsonValidationErrors('confirmar_eliminacion');
        }
        $this->assertSame($before, $this->snapshot());
    }

    public function test_empresa_vacia_y_ausente(): void
    {
        $this->deleteJson('/api/empresas/3', ['confirmar_eliminacion' => true])->assertOk()->assertJsonPath('data.usuarios_eliminados', 0);
        $this->delete('/api/empresas/999', ['confirmar_eliminacion' => true])->assertNotFound()->assertJsonStructure(['message']);
    }

    public function test_fallo_final_revierte_incluso_hijos_ya_borrados_sin_trazas(): void
    {
        config(['app.debug' => true]);
        $before = $this->snapshot();
        Empresa::deleting(function () { throw new \RuntimeException('QA fallo SQL privado'); });
        $this->delete('/api/empresas/1', ['confirmar_eliminacion' => true])->assertStatus(500)
            ->assertExactJson(['message' => 'No se pudo eliminar la empresa. No se guardaron cambios.']);
        $this->assertSame($before, $this->snapshot());
    }

    public function test_referencia_restrictiva_inesperada_revierte_todo(): void
    {
        Schema::create('referencia_qa', function (Blueprint $t) { $t->id(); $t->foreignId('empresa_id')->constrained('empresas')->restrictOnDelete(); });
        DB::table('referencia_qa')->insert(['empresa_id' => 1]);
        $before = $this->snapshot();
        $this->deleteJson('/api/empresas/1', ['confirmar_eliminacion' => true])->assertStatus(409);
        $this->assertSame($before, $this->snapshot());
    }

    public function test_pago_de_otra_empresa_no_se_borra_por_relacion_cruzada(): void
    {
        DB::table('pagos')->where('id', 2)->update(['id_suscripciones' => 1]);
        $before = $this->snapshot();
        $this->deleteJson('/api/empresas/1', ['confirmar_eliminacion' => true])->assertStatus(409);
        $this->assertSame($before, $this->snapshot());
    }
}
