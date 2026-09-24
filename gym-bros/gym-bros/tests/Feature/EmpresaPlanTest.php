<?php

namespace Tests\Feature;

use App\Models\Empresa;
use App\Models\Suscripcion;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class EmpresaPlanTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->actuarComoAdministrador();
        Carbon::setTestNow('2026-09-16 12:00:00');
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        foreach (['2026_08_21_224135_create_empresas.php', '2026_08_21_224524_create_planes.php',
            '2026_08_21_224533_create_suscripciones.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        foreach ([[1, true, 30], [2, true, 1], [3, false, 30], [4, true, 0], [5, true, -1]] as [$id, $active, $days]) {
            DB::table('planes')->insert(['id' => $id, 'nombre' => 'Plan QA', 'descripcion' => 'QA',
                'precio_original' => 100, 'precio_inicial' => 90, 'duracion_dias' => $days,
                'limite_usuarios' => 50, 'activo' => $active, 'enlace_whatsapp' => 'https://example.invalid']);
        }
        Empresa::create($this->payload());
        Empresa::create($this->payload());
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        DB::disconnect('sqlite');
        parent::tearDown();
    }

    private function payload(): array
    {
        $data = ['nombre' => 'Gym QA', 'nombre_gerente' => 'QA', 'telefono' => '999999999',
            'correo' => 'qa@example.invalid', 'estado' => true, 'fecha_registro' => '2026-09-01',
            'logo' => 'empresas/logo.webp', 'color_1' => '#111111', 'color_2' => '#ffffff'];
        foreach (['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'] as $day) {
            $data['horario_inicio_'.$day] = 8;
            $data['horario_fin_'.$day] = 20;
        }

        return $data;
    }

    private function subscription(int $company = 1, string $state = 'activa', string $end = '2026-10-01'): Suscripcion
    {
        return Suscripcion::create(['id_empresas' => $company, 'id_planes' => 1,
            'fecha_inicio' => '2026-09-01', 'fecha_fin' => $end, 'estado' => $state,
            'renovacion_automatica' => false]);
    }

    public function test_creacion_con_plan_y_fechas_inclusivas(): void
    {
        $this->postJson('/api/empresas', $this->payload() + ['id_planes' => 1])
            ->assertCreated()->assertJsonPath('data.suscripcion.id_planes', 1)
            ->assertJsonPath('data.suscripcion.fecha_inicio', '2026-09-16')
            ->assertJsonPath('data.suscripcion.fecha_fin', '2026-10-15')
            ->assertJsonPath('data.suscripcion.estado', 'activa');
        $this->assertDatabaseCount('empresas', 3);
        $this->assertDatabaseCount('suscripciones', 1);
        $this->assertDatabaseHas('suscripciones', ['id_empresas' => 3, 'renovacion_automatica' => false]);
    }

    public function test_sin_plan_y_null_preservan_comportamiento(): void
    {
        $old = $this->subscription();
        $this->postJson('/api/empresas', $this->payload())->assertCreated()->assertJsonMissingPath('data.suscripcion');
        $this->putJson('/api/empresas/1', ['nombre' => 'Editado'])->assertOk()->assertJsonMissingPath('data.suscripcion');
        $this->putJson('/api/empresas/1', ['id_planes' => null])->assertOk();
        $this->assertDatabaseCount('suscripciones', 1);
        $this->assertEquals($old->getAttributes(), $old->fresh()->getAttributes());
    }

    public function test_cambio_plan_preserva_historial_y_otra_empresa(): void
    {
        $old = $this->subscription();
        $other = $this->subscription(2);
        $this->putJson('/api/empresas/1', ['id_planes' => 2])->assertOk()
            ->assertJsonPath('data.suscripcion.fecha_fin', '2026-09-16');
        $this->assertSame('cancelada', $old->fresh()->estado);
        $this->assertSame($old->fecha_fin, $old->fresh()->fecha_fin);
        $this->assertEquals($other->getAttributes(), $other->fresh()->getAttributes());
        $this->assertDatabaseCount('suscripciones', 3);
    }

    public function test_reintento_mismo_plan_no_duplica_ni_extiende(): void
    {
        $old = $this->subscription();
        for ($i = 0; $i < 2; $i++) {
            $this->putJson('/api/empresas/1', ['id_planes' => 1, 'nombre' => 'Editado'])
                ->assertOk()->assertJsonPath('data.suscripcion.id', $old->id);
        }
        $this->assertDatabaseCount('suscripciones', 1);
        $this->assertEquals($old->getAttributes(), $old->fresh()->getAttributes());
    }

    public function test_plan_invalido_inactivo_o_duracion_invalida_no_guarda(): void
    {
        foreach ([999, 3, 4, 5, 'no', [1], 1.5] as $id) {
            $this->post('/api/empresas', $this->payload() + ['id_planes' => $id])
                ->assertUnprocessable()->assertJsonValidationErrors('id_planes');
            $this->put('/api/empresas/1', ['nombre' => 'No guardar', 'id_planes' => $id])
                ->assertUnprocessable()->assertJsonValidationErrors('id_planes');
        }
        $this->assertDatabaseCount('empresas', 2);
        $this->assertDatabaseCount('suscripciones', 0);
        $this->assertDatabaseHas('empresas', ['id' => 1, 'nombre' => 'Gym QA']);
    }

    public function test_vencidas_se_renuevan_y_otros_estados_se_conservan(): void
    {
        $expired = $this->subscription(1, 'activa', '2026-09-15');
        $pending = $this->subscription(1, 'pendiente');
        $this->putJson('/api/empresas/1', ['id_planes' => 1])->assertOk();
        $this->assertSame('vencida', $expired->fresh()->estado);
        $this->assertEquals($pending->getAttributes(), $pending->fresh()->getAttributes());
        $this->assertDatabaseCount('suscripciones', 3);
    }

    public function test_fallo_suscripcion_revierte_empresa_historial_y_archivo(): void
    {
        Storage::fake('public');
        $old = $this->subscription();
        Suscripcion::creating(function () { throw new \RuntimeException('Fallo QA'); });
        try {
            $this->postJson('/api/empresas', array_replace($this->payload(), [
                'id_planes' => 2, 'logo' => UploadedFile::fake()->image('logo.png')]))
                ->assertStatus(500)->assertExactJson(['message' => 'No se pudo guardar la empresa y su suscripcion.']);
            $this->putJson('/api/empresas/1', ['nombre' => 'No guardar', 'id_planes' => 2])
                ->assertStatus(500)->assertExactJson(['message' => 'No se pudo guardar la empresa y su suscripcion.']);
        } finally {
            Suscripcion::flushEventListeners();
        }
        $this->assertDatabaseCount('empresas', 2);
        $this->assertDatabaseCount('suscripciones', 1);
        $this->assertEquals($old->getAttributes(), $old->fresh()->getAttributes());
        $this->assertDatabaseHas('empresas', ['id' => 1, 'nombre' => 'Gym QA']);
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_empresa_inexistente_y_campos_suscripcion_no_editables(): void
    {
        $this->putJson('/api/empresas/999', ['id_planes' => 1])->assertNotFound();
        $this->putJson('/api/empresas/1', ['id_planes' => 1, 'id_empresas' => 2,
            'fecha_fin' => '2099-01-01', 'renovacion_automatica' => true])->assertOk()
            ->assertJsonPath('data.suscripcion.id_empresas', 1)
            ->assertJsonPath('data.suscripcion.fecha_fin', '2026-10-15')
            ->assertJsonPath('data.suscripcion.renovacion_automatica', false);
    }

    public function test_cambio_de_ano_y_duracion_fuera_del_rango_de_fecha(): void
    {
        Carbon::setTestNow('2026-12-31 23:59:59');
        $this->putJson('/api/empresas/1', ['id_planes' => 1])->assertOk()
            ->assertJsonPath('data.suscripcion.fecha_fin', '2027-01-29');
        DB::table('planes')->where('id', 2)->update(['duracion_dias' => 2147483647]);
        $this->put('/api/empresas/1', ['id_planes' => 2, 'nombre' => 'No guardar'])
            ->assertUnprocessable()->assertJsonValidationErrors('id_planes');
        $this->assertDatabaseHas('empresas', ['id' => 1, 'nombre' => 'Gym QA']);
        $this->assertDatabaseCount('suscripciones', 1);
    }

    public function test_creacion_con_imagen_y_plan_nulo_o_valido(): void
    {
        Storage::fake('public');
        foreach ([null, 1] as $idPlan) {
            $response = $this->postJson('/api/empresas', array_replace($this->payload(), [
                'id_planes' => $idPlan, 'logo' => UploadedFile::fake()->image('logo.png')]))->assertCreated();
            Storage::disk('public')->assertExists($response->json('data.logo'));
        }
        $this->assertDatabaseCount('empresas', 4);
        $this->assertDatabaseCount('suscripciones', 1);
    }
}
