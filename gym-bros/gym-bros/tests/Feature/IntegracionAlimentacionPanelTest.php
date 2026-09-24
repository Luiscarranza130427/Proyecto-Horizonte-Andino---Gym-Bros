<?php

namespace Tests\Feature;

use App\Models\PlanAlimentacion;
use Illuminate\Support\Facades\DB;
use Tests\Support\EscenarioMultiempresa;
use Tests\TestCase;

class IntegracionAlimentacionPanelTest extends TestCase
{
    use EscenarioMultiempresa;

    protected function setUp(): void
    {
        parent::setUp();
        $this->prepararEscenario();
        foreach ([1 => self::USUARIO_A1, 2 => self::USUARIO_B1] as $id => $usuario) {
            PlanAlimentacion::create(['id' => $id, 'id_usuarios' => $usuario, 'nombre' => 'Plan QA', 'descripcion' => 'QA',
                'objetivo' => 'salud', 'calorias_objetivo' => 2000, 'proteinas_objetivo' => 100,
                'carbohidratos_objetivo' => 250, 'grasas_objetivo' => 60,
                'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-09-30', 'estado' => true]);
        }
        DB::table('alimentos')->insert(['id' => 1, 'nombre' => 'Arroz QA', 'tipo' => 'cereal', 'calorias' => 120,
            'proteinas' => 3, 'carbohidratos' => 25, 'grasas' => 1, 'fibra' => 2, 'activo' => true,
            'base_unidad' => 'gramos', 'estado_preparacion' => 'cocido', 'fuente_nutricional' => 'QA']);
        $this->como(self::EMPRESA_A);
    }

    private function comida(): array
    {
        return ['tipo_comida' => 'almuerzo', 'hora_sugerida' => '13:00',
            'alimentos' => [['id_alimentos' => 1, 'cantidad' => 150, 'unidad' => 'gramos']]];
    }

    public function test_listados_y_detalle_respetan_contrato_y_empresa(): void
    {
        $this->getJson('/api/planes-alimentacion?page=1&per_page=1&activo=true')->assertOk()
            ->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.usuario.id', self::USUARIO_A1)
            ->assertJsonPath('data.0.empresa.id', 1)->assertJsonPath('data.0.activo', true);
        $this->getJson('/api/planes-alimentacion/empresas')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', 1);
        $this->getJson('/api/planes-alimentacion/2')->assertNotFound();
        $this->getJson('/api/planes-alimentacion?id_empresas=2')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/alimentos?search=Arroz&type=cereal&page=1&per_page=1')->assertOk()->assertJsonPath('meta.total', 1);
        $this->getJson('/api/alimentos?search=Inexistente&page=1')->assertOk()->assertJsonPath('meta.total', 0);
        $this->getJson('/api/alimentos/para-elegir')->assertOk()->assertJsonPath('data.0.id', 1);
        $this->getJson('/api/alimentos')->assertOk()->assertJsonMissingPath('meta')->assertJsonCount(1, 'data');
    }

    public function test_una_porcion_historica_sin_conversion_no_tumba_el_listado(): void
    {
        // Dato real encontrado en MySQL: porcion en mililitros de un alimento
        // con base en gramos y sin densidad. Antes todo el listado daba 422.
        $comida = DB::table('comidas')->insertGetId(['id_planes_alimentacion' => 1, 'nombre' => 'cena', 'tipo' => 'cena',
            'hora_sugerida' => '20:00', 'notas' => '', 'dia' => 1, 'fecha' => '2026-09-01', 'orden' => 1]);
        DB::table('comida_alimentos')->insert(['id_comidas' => $comida, 'id_alimentos' => 1, 'cantidad' => 200,
            'unidad' => 'mililitros', 'notas' => '']);

        $this->getJson('/api/planes-alimentacion?page=1&per_page=10')->assertOk()
            ->assertJsonPath('data.0.comidas.0.alimentos.0.macros_calculables', false)
            ->assertJsonPath('data.0.comidas.0.alimentos.0.macros.calorias', 0);
        $this->getJson('/api/planes-alimentacion/1')->assertOk();
    }

    public function test_comidas_crud_calcula_porciones_y_es_atomico(): void
    {
        $id = $this->postJson('/api/planes-alimentacion/1/comidas', $this->comida())->assertCreated()
            ->assertJsonPath('data.macros.calorias', 180)->json('data.id');
        $this->getJson('/api/planes-alimentacion/1')->assertOk()->assertJsonPath('data.comidas_count', 1)
            ->assertJsonPath('data.macros.calorias', 180);
        $datos = $this->comida();
        $datos['alimentos'][0]['cantidad'] = 200;
        $datos['hora_sugerida'] = '13:00:00';
        $this->putJson("/api/planes-alimentacion/1/comidas/$id", $datos)->assertOk()->assertJsonPath('data.macros.calorias', 240);
        $datos['alimentos'][0]['unidad'] = 'unidad';
        $this->putJson("/api/planes-alimentacion/1/comidas/$id", $datos)->assertUnprocessable();
        $this->assertDatabaseHas('comida_alimentos', ['id_comidas' => $id, 'cantidad' => 200, 'unidad' => 'gramos']);
        $this->deleteJson("/api/planes-alimentacion/2/comidas/$id")->assertNotFound();
        $this->assertDatabaseHas('comidas', ['id' => $id]);
        $this->deleteJson("/api/planes-alimentacion/1/comidas/$id")->assertOk();
        $this->assertDatabaseMissing('comida_alimentos', ['id_comidas' => $id]);
        $this->como(self::USUARIO_A1);
        $this->postJson('/api/planes-alimentacion/1/comidas', $this->comida())->assertForbidden();
    }

    public function test_preferencias_persisten_solo_para_el_actor(): void
    {
        $this->putJson('/api/perfil/preferencias', ['notifEmail' => false, 'id_usuarios' => self::USUARIO_B1])
            ->assertOk()->assertJsonPath('data.notifEmail', false);
        $this->getJson('/api/perfil/preferencias')->assertOk()->assertJsonPath('data.notifEmail', false);
        $this->putJson('/api/perfil/preferencias', ['idioma' => 'invalido'])->assertUnprocessable();
        $this->como(self::USUARIO_B1);
        $this->getJson('/api/perfil/preferencias')->assertOk()->assertJsonPath('data.notifEmail', true);
    }

    public function test_edicion_web_preserva_el_contrato_del_plan_movil(): void
    {
        \App\Models\EvaluacionFisica::create(['id_usuarios' => self::USUARIO_A1,
            'nivel_experiencia' => '1a3meses', 'actividad_diaria' => 'moderadamente_activo', 'objetivo' => 'salud',
            'edad' => 30, 'peso' => 70, 'altura' => 170, 'porcentaje_grasa' => 20, 'masa_muscular' => 30,
            'cintura' => 80, 'pecho' => 90, 'brazo' => 30, 'muslo' => 50, 'cadera' => 90,
            'dias_semana' => 3, 'eleccion_dias' => ['Lunes', 'Miercoles', 'Viernes'],
            'tiempo_sesion_min' => 60, 'restricciones' => 'sin-restricciones', 'fecha_evaluacion' => '2026-09-01']);
        PlanAlimentacion::findOrFail(1)->update(['id_evaluaciones_fisicas' => 1, 'calculo' => [
            'distribucion' => ['almuerzo' => 0.4], 'objetivos' => ['calorias' => 2000, 'proteinas' => 100,
                'carbohidratos' => 250, 'grasas' => 60, 'fibra' => 25]]]);
        $datos = $this->comida();
        $datos['tipo_comida'] = 'snack';
        $this->postJson('/api/planes-alimentacion/1/comidas', $datos)->assertCreated();
        $this->como(self::USUARIO_A1);
        $this->getJson('/api/usuarios/'.self::USUARIO_A1.'/planesalimentacion/1')->assertOk()
            ->assertJsonPath('data.dias.0.comidas.0.alimentos.0.detalle_nutricional.base_cantidad', 100)
            ->assertJsonPath('data.dias.0.comidas.0.alimentos.0.detalle_nutricional.base_unidad', 'gramos')
            ->assertJsonPath('data.totales_plan.calorias', 180);
    }
}
