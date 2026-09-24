<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Support\EscenarioMultiempresa;
use Tests\TestCase;

/**
 * Permisos por rol y aislamiento por empresa: cambiar un ID en la URL no debe
 * dar acceso a datos de otro usuario u otra empresa.
 */
class AutorizacionRolesTest extends TestCase
{
    use EscenarioMultiempresa;

    protected function setUp(): void
    {
        parent::setUp();
        $this->prepararEscenario();
    }

    public function test_sin_token_todo_lo_privado_devuelve_401_y_lo_publico_sigue_abierto(): void
    {
        foreach (['/api/usuarios', '/api/usuarios/4', '/api/empresas', '/api/empresas/1', '/api/pagos', '/api/pagos/1',
            '/api/suscripciones', '/api/rutinas', '/api/evaluacionesfisicas', '/api/notificaciones', '/api/banners',
            '/api/ejercicios', '/api/alimentos', '/api/progresos', '/api/usuarios/4/resumen-web', '/api/empresa/banners/4'] as $uri) {
            $this->getJson($uri)->assertUnauthorized();
        }
        $this->putJson('/api/usuarios/4', ['nombres' => 'X'])->assertUnauthorized();
        $this->putJson('/api/usuarios/4/estado', ['estado' => 0])->assertUnauthorized();
        $this->deleteJson('/api/empresas/2')->assertUnauthorized();
        $this->postJson('/api/rutinas/generar/4')->assertUnauthorized();
        $this->getJson('/api/planes')->assertOk();
        $this->assertDatabaseHas('usuarios', ['id' => 4, 'nombres' => '[QA] Usuario', 'estado' => 1]);
        $this->assertDatabaseHas('empresas', ['id' => 2]);
    }

    public function test_usuario_solo_ve_y_edita_lo_propio(): void
    {
        $this->como(self::USUARIO_A1);
        $this->assertSame([self::USUARIO_A1], $this->ids('/api/usuarios'));
        $this->getJson('/api/usuarios/'.self::USUARIO_A1)->assertOk();
        foreach ([self::USUARIO_A2, self::USUARIO_B1, self::ADMIN] as $ajeno) {
            $this->getJson("/api/usuarios/$ajeno")->assertForbidden();
            $this->putJson("/api/usuarios/$ajeno", ['nombres' => 'Hackeado'])->assertForbidden();
            $this->post("/api/usuarios/$ajeno/foto-perfil", ['foto_perfil' => UploadedFile::fake()->image('x.png')], ['Accept' => 'application/json'])->assertForbidden();
            $this->getJson("/api/usuarios/$ajeno/empresa")->assertForbidden();
            $this->getJson("/api/empresa/banners/$ajeno")->assertForbidden();
            $this->getJson("/api/usuarios/$ajeno/evaluaciones/perfil")->assertForbidden();
            $this->postJson("/api/rutinas/generar/$ajeno")->assertForbidden();
            $this->getJson("/api/usuarios/$ajeno/perfil-alimentario")->assertForbidden();
        }
        $this->getJson('/api/usuarios/'.self::USUARIO_B1.'/rutinas/'.self::USUARIO_B1.'/sesiones/1')->assertForbidden();
        $this->assertDatabaseMissing('usuarios', ['nombres' => 'Hackeado']);

        $this->putJson('/api/usuarios/'.self::USUARIO_A1, ['nombres' => 'Nuevo nombre'])->assertOk();
        // No puede alargarse la suscripcion ni desactivar/activar cuentas.
        $this->putJson('/api/usuarios/'.self::USUARIO_A1, ['fin_suscripcion' => '2030-12-31'])->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_A1.'/estado', ['estado' => 1])->assertForbidden();
        $this->assertDatabaseHas('usuarios', ['id' => self::USUARIO_A1, 'nombres' => 'Nuevo nombre', 'fin_suscripcion' => null]);

        $this->assertSame([1], $this->ids('/api/empresas'));
        $this->getJson('/api/empresas/2')->assertForbidden();
        $this->putJson('/api/empresas/1', ['nombre' => 'X'])->assertForbidden();
        $this->assertSame([self::USUARIO_A1], $this->ids('/api/rutinas'));
        $this->assertSame([1, 3], $this->ids('/api/notificaciones'));
        foreach (['/api/pagos', '/api/pagos/1', '/api/suscripciones', '/api/historialcambios'] as $uri) {
            $this->getJson($uri)->assertForbidden();
        }
        $this->postJson('/api/banners', [])->assertForbidden();
        $this->putJson('/api/alimentos/1', ['nombre' => 'X'])->assertForbidden();
        $this->deleteJson('/api/empresas/1')->assertForbidden();
    }

    public function test_empresa_gestiona_su_gimnasio_y_nada_de_otro(): void
    {
        $this->como(self::EMPRESA_A);
        $this->assertSame([1, 2, 3, 4, 5], $this->ids('/api/usuarios'));
        $this->getJson('/api/usuarios/'.self::USUARIO_B1)->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_B1, ['nombres' => 'X'])->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_B1.'/estado', ['estado' => 0])->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_A1.'/estado', ['estado' => 0])->assertOk();
        $this->putJson('/api/usuarios/'.self::EMPRESA_A.'/estado', ['estado' => 0])->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_A2, ['fin_suscripcion' => '2026-12-31'])->assertOk();
        $this->assertDatabaseHas('usuarios', ['id' => self::USUARIO_B1, 'estado' => 1]);
        $this->assertDatabaseHas('usuarios', ['id' => self::EMPRESA_A, 'estado' => 1]);

        $this->assertSame([1], $this->ids('/api/empresas'));
        $this->putJson('/api/empresas/1', ['nombre' => '[QA] Empresa A editada'])->assertOk();
        // Plan, estado y fecha de alta solo los cambia la plataforma.
        foreach (['id_planes' => 1, 'estado' => false, 'fecha_registro' => '2020-01-01'] as $campo => $valor) {
            $this->putJson('/api/empresas/1', [$campo => $valor])->assertForbidden();
        }
        $this->putJson('/api/empresas/2', ['nombre' => 'X'])->assertForbidden();
        $this->postJson('/api/empresas/2/logo', [])->assertForbidden();
        $this->putJson('/api/empresa/banners/2', ['banner_2' => 'x'])->assertForbidden();
        $this->deleteJson('/api/empresas/1')->assertForbidden();
        $this->postJson('/api/empresas', [])->assertForbidden();
        $this->putJson('/api/empresas/1/ejercicios/1/estado', ['estado' => 1])->assertNotFound();

        $this->assertSame([1], $this->ids('/api/pagos'));
        $this->getJson('/api/pagos/2')->assertForbidden();
        $this->getJson('/api/pagos/1')->assertOk();
        $this->assertSame([1], $this->ids('/api/suscripciones'));
        $this->assertSame([self::USUARIO_A1], $this->ids('/api/rutinas'));
        $this->assertSame([1, 3], $this->ids('/api/notificaciones'));
        $this->assertDatabaseHas('empresas', ['id' => 2, 'nombre' => '[QA] Empresa B']);
    }

    public function test_entrenador_hace_seguimiento_pero_no_administra_cuentas(): void
    {
        $this->como(self::ENTRENADOR_A);
        $this->getJson('/api/usuarios/'.self::USUARIO_A1)->assertOk();
        $this->getJson('/api/usuarios/'.self::USUARIO_A1.'/rutinas/'.self::USUARIO_A1.'/sesiones/1')->assertNotFound();
        $this->putJson('/api/usuarios/'.self::USUARIO_A1, ['nombres' => 'X'])->assertForbidden();
        $this->putJson('/api/usuarios/'.self::USUARIO_A1.'/estado', ['estado' => 0])->assertForbidden();
        $this->getJson('/api/usuarios/'.self::USUARIO_B1)->assertForbidden();
        $this->getJson('/api/usuarios/'.self::USUARIO_B1.'/perfil-alimentario')->assertForbidden();
        $this->putJson('/api/empresas/1', ['nombre' => 'X'])->assertForbidden();
        $this->getJson('/api/pagos')->assertForbidden();
        $this->getJson('/api/usuarios/exportar')->assertForbidden();
        $this->assertSame([1, 2, 3, 4, 5], $this->ids('/api/usuarios'));
    }

    public function test_administrador_ve_todo_y_recibe_404_reales(): void
    {
        $this->como(self::ADMIN);
        $this->assertSame([1, 2, 3, 4, 5, 6, 7], $this->ids('/api/usuarios'));
        $this->assertSame([1, 2], $this->ids('/api/empresas'));
        $this->assertSame([1, 2], $this->ids('/api/pagos'));
        $this->assertSame([self::USUARIO_A1, self::USUARIO_B1], $this->ids('/api/rutinas'));
        $this->getJson('/api/usuarios/999')->assertNotFound();
        $this->getJson('/api/empresas/999')->assertNotFound();
        $this->putJson('/api/empresas/2', ['estado' => false])->assertOk();
        $this->putJson('/api/usuarios/'.self::ADMIN.'/estado', ['estado' => 0])->assertForbidden();
    }

    public function test_la_edicion_ignora_rol_estado_y_empresa_y_protege_la_suscripcion(): void
    {
        DB::table("usuarios")->where("id", self::USUARIO_A1)->update(["fin_suscripcion" => "2026-09-30"]);
        $this->como(self::USUARIO_A1);
        // El formulario reenvia valores actuales: no son cambios y no deben dar 403.
        $this->putJson("/api/usuarios/".self::USUARIO_A1, ["nombres" => "Yo", "fin_suscripcion" => "2026-09-30",
            "tipo_usuario" => "Administrador", "estado" => false, "id_empresas" => 2])->assertOk();
        $this->assertDatabaseHas("usuarios", ["id" => self::USUARIO_A1, "nombres" => "Yo",
            "tipo_usuario" => "Usuario", "estado" => 1, "id_empresas" => 1, "fin_suscripcion" => "2026-09-30"]);
        $this->putJson("/api/usuarios/".self::USUARIO_A1, ["fin_suscripcion" => "2030-01-01"])->assertForbidden();

        $this->como(self::EMPRESA_A);
        $this->putJson("/api/usuarios/".self::USUARIO_A1, ["fin_suscripcion" => "2026-12-31"])->assertOk();
        $this->assertDatabaseHas("usuarios", ["id" => self::USUARIO_A1, "fin_suscripcion" => "2026-12-31"]);
    }

    public function test_cuenta_inactiva_pierde_acceso_aunque_tenga_token(): void
    {
        $this->como(self::EMPRESA_A);
        DB::table('usuarios')->where('id', self::EMPRESA_A)->update(['estado' => false]);
        $this->como(self::EMPRESA_A);
        $this->getJson('/api/usuarios')->assertForbidden()->assertJsonPath('message', 'La cuenta esta inactiva.');
    }

    public function test_banners_parciales_no_borran_lo_no_enviado_y_se_validan(): void
    {
        $this->como(self::EMPRESA_A);
        $this->putJson('/api/empresa/banners/1', ['banner_2' => 'empresas/b2.webp'])->assertOk()
            ->assertJsonPath('banner_1', 'empresas/b1.webp')->assertJsonPath('link_boton_1', 'https://qa.test/1');
        $this->putJson('/api/empresa/banners/1', [])->assertUnprocessable();
        $this->putJson('/api/empresa/banners/1', ['link_boton_1' => str_repeat('x', 201)])->assertUnprocessable();
        $this->getJson('/api/empresa/banners/'.self::USUARIO_A1)->assertOk()
            ->assertJsonPath('banner_2_url', 'http://localhost/storage/empresas/b2.webp');
    }

    public function test_rutas_de_imagen_historicas_salen_como_url_publica(): void
    {
        $this->como(self::ADMIN);
        $this->getJson('/api/usuarios/'.self::USUARIO_A1)->assertOk()
            ->assertJsonPath('data.foto_perfil_url', 'http://localhost/storage/usuario/foto4.jpg');
        $this->getJson('/api/empresas/1')->assertOk()
            ->assertJsonPath('data.logo_url', 'http://localhost/storage/empresas/logo.webp')
            ->assertJsonPath('data.banner_2_url', null);
    }
}
