<?php

namespace Tests\Feature;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\Support\EscenarioMultiempresa;
use Tests\TestCase;

/**
 * Endpoints que el panel web ya consumia y la API no publicaba: planes
 * comerciales, notificaciones, metricas de pagos, alta de usuarios, edicion de
 * ejercicios, alta de alimentos, historial y perfil.
 */
class EndpointsPanelTest extends TestCase
{
    use EscenarioMultiempresa;

    protected function setUp(): void
    {
        parent::setUp();
        $this->prepararEscenario();
    }

    private function plan(array $cambios = []): array
    {
        return $cambios + ['nombre' => '[QA] Plan nuevo', 'descripcion' => 'QA', 'precio_original' => 150,
            'precio_inicial' => 120.5, 'duracion_dias' => 60, 'limite_usuarios' => 80, 'activo' => true,
            'contenido' => 'WhatsApp', 'enlace_whatsapp' => 'https://wa.me/51999999999'];
    }

    public function test_planes_crud_solo_administrador_y_validaciones(): void
    {
        $this->getJson('/api/planes/1')->assertOk()->assertJsonPath('data.nombre', 'Plan QA');
        $this->getJson('/api/planes/999')->assertNotFound();
        $this->postJson('/api/planes', $this->plan())->assertUnauthorized();

        $this->como(self::EMPRESA_A);
        $this->postJson('/api/planes', $this->plan())->assertForbidden();
        $this->putJson('/api/planes/1', ['nombre' => 'X'])->assertForbidden();
        $this->deleteJson('/api/planes/1')->assertForbidden();

        $this->como(self::ADMIN);
        $id = $this->postJson('/api/planes', $this->plan())->assertCreated()
            ->assertJsonPath('data.duracion_dias', 60)->json('data.id');
        $this->postJson('/api/planes', $this->plan(['precio_inicial' => 200]))->assertUnprocessable()->assertJsonValidationErrors('precio_inicial');
        $this->postJson('/api/planes', $this->plan(['duracion_dias' => 0, 'enlace_whatsapp' => 'no-es-url']))
            ->assertUnprocessable()->assertJsonValidationErrors(['duracion_dias', 'enlace_whatsapp']);
        $this->putJson("/api/planes/$id", ['activo' => false])->assertOk()->assertJsonPath('data.activo', 0);
        $this->putJson("/api/planes/$id", ['nombre' => null])->assertUnprocessable();
        $this->putJson("/api/planes/$id", [])->assertUnprocessable()->assertJsonValidationErrors('datos');
        $this->assertSame([1], collect($this->getJson('/api/planes?estado=activo')->json('data'))->pluck('id')->all());
        // Con suscripciones: no se borra el historial comercial.
        $this->deleteJson('/api/planes/1')->assertStatus(409);
        $this->deleteJson("/api/planes/$id")->assertOk();
        $this->assertDatabaseMissing('planes', ['id' => $id]);
        $this->assertDatabaseHas('planes', ['id' => 1]);
    }

    public function test_notificaciones_crear_programar_enviar_y_retirar_por_empresa(): void
    {
        $this->como(self::USUARIO_A1);
        $this->postJson('/api/notificaciones', ['alcance' => 'todos', 'tipo' => 'otro', 'titulo' => 'X', 'mensaje' => 'X'])->assertForbidden();
        $this->getJson('/api/notificaciones/programadas')->assertForbidden();

        $this->como(self::EMPRESA_A);
        $this->postJson('/api/notificaciones', ['alcance' => 'empresa', 'id_empresas' => 2, 'tipo' => 'otro',
            'titulo' => 'X', 'mensaje' => 'X'])->assertForbidden();
        $programada = $this->postJson('/api/notificaciones', ['alcance' => 'todos', 'tipo' => 'recordatorio',
            'titulo' => '[QA] Programada', 'mensaje' => 'QA', 'programar' => true, 'fecha_envio' => now()->addDay()->toDateTimeString()])
            ->assertCreated()->assertJsonPath('data.id_empresas', 1)->assertJsonPath('data.enviada', false)->json('data.id');
        $this->postJson('/api/notificaciones', ['alcance' => 'todos', 'tipo' => 'recordatorio', 'titulo' => 'X',
            'mensaje' => 'X', 'programar' => true, 'fecha_envio' => now()->subDay()->toDateTimeString()])
            ->assertUnprocessable()->assertJsonValidationErrors('fecha_envio');
        $this->postJson('/api/notificaciones', ['alcance' => 'todos', 'tipo' => 'invalido', 'titulo' => '', 'mensaje' => ''])
            ->assertUnprocessable()->assertJsonValidationErrors(['tipo', 'titulo', 'mensaje']);
        $this->assertSame([$programada], collect($this->getJson('/api/notificaciones/programadas')->json('data'))->pluck('id')->all());
        // Una programada no aparece como recibida hasta enviarse.
        $this->assertNotContains($programada, collect($this->getJson('/api/notificaciones/activas')->json('data'))->pluck('id'));
        $this->postJson("/api/notificaciones/$programada/enviar-ahora")->assertOk()->assertJsonPath('data.enviada', true);
        $this->postJson("/api/notificaciones/$programada/enviar-ahora")->assertStatus(409);
        $this->deleteJson("/api/notificaciones/$programada")->assertStatus(409);
        // Notificacion de otra empresa: existe pero no es gestionable.
        $this->deleteJson('/api/notificaciones/2')->assertForbidden();
        $this->postJson('/api/notificaciones/2/enviar-ahora')->assertForbidden();
        $this->deleteJson('/api/notificaciones/999')->assertNotFound();
        $this->assertSame(2, collect($this->getJson('/api/notificaciones?enviada=1&page=1&per_page=10')->json('data'))->count() - 1);

        $this->como(self::ADMIN);
        $this->postJson('/api/notificaciones', ['alcance' => 'empresa', 'tipo' => 'sistema', 'titulo' => 'X', 'mensaje' => 'X'])
            ->assertUnprocessable()->assertJsonValidationErrors('id_empresas');
        $general = $this->postJson('/api/notificaciones', ['alcance' => 'todos', 'tipo' => 'sistema', 'titulo' => '[QA] General',
            'mensaje' => 'QA', 'programar' => true, 'fecha_envio' => now()->addHour()->toDateTimeString()])
            ->assertCreated()->assertJsonPath('data.id_empresas', null)->json('data.id');
        $this->deleteJson("/api/notificaciones/$general")->assertOk();
        $this->assertDatabaseMissing('notificaciones', ['id' => $general]);
    }

    public function test_metricas_de_pagos_respetan_alcance_y_filtros(): void
    {
        $this->como(self::ADMIN);
        $this->getJson('/api/pagos/metricas')->assertOk()->assertJsonPath('data.totalIngresos', 180)
            ->assertJsonPath('data.totalTransacciones', 2)->assertJsonPath('data.ticketPromedio', 90)
            ->assertJsonPath('data.moneda', 'PEN');
        $this->getJson('/api/pagos/metricas?empresa_id=2')->assertOk()->assertJsonPath('data.totalTransacciones', 1);
        $this->getJson('/api/pagos?page=1&per_page=1')->assertOk()->assertJsonPath('meta.total', 2)->assertJsonCount(1, 'data');
        $this->getJson('/api/pagos/metricas?empresa_id=abc')->assertUnprocessable();

        $this->como(self::EMPRESA_A);
        // Aunque pida la otra empresa, el alcance de su sesion manda.
        $this->getJson('/api/pagos/metricas?empresa_id=2')->assertOk()->assertJsonPath('data.totalTransacciones', 0);
        $this->getJson('/api/pagos/metricas')->assertOk()->assertJsonPath('data.totalIngresos', 90);
        $this->como(self::ENTRENADOR_A);
        $this->getJson('/api/pagos/metricas')->assertForbidden();
    }

    public function test_alta_de_usuario_sin_contrasena_utilizable_y_limitada_a_la_empresa(): void
    {
        Queue::fake();
        $datos = ['nombres' => '[QA] Nuevo', 'apellidos' => 'Alta', 'apodo' => 'nuevo', 'genero' => 'Mujer',
            'correo' => ' Nuevo.QA@GymBros.test ', 'tipo_documento' => 'DNI', 'numero_documento' => '12345678',
            'telefono' => '999888777', 'fecha_nacimiento' => '2000-05-05', 'tipo_usuario' => 'Usuario'];

        $this->como(self::USUARIO_A1);
        $this->postJson('/api/usuarios', $datos)->assertForbidden();

        $this->como(self::EMPRESA_A);
        $this->postJson('/api/usuarios', $datos + ['id_empresas' => 2])->assertForbidden();
        $this->postJson('/api/usuarios', ['tipo_usuario' => 'Administrador'] + $datos)->assertUnprocessable()->assertJsonValidationErrors('tipo_usuario');
        $id = $this->postJson('/api/usuarios', $datos)->assertCreated()
            ->assertJsonPath('data.id_empresas', 1)->assertJsonPath('data.correo', 'nuevo.qa@gymbros.test')
            ->assertJsonMissingPath('data.password_hash')->json('data.id');
        $this->assertStringStartsWith('!pendiente:', DB::table('usuarios')->where('id', $id)->value('password_hash'));
        $this->postJson('/api/usuarios', $datos)->assertUnprocessable()->assertJsonValidationErrors('correo');
        $this->postJson('/api/usuarios', ['correo' => 'no-es-correo', 'fecha_nacimiento' => '2999-01-01'] + $datos)
            ->assertUnprocessable()->assertJsonValidationErrors(['correo', 'fecha_nacimiento']);
        // La cuenta nueva no puede iniciar sesion hasta crear su contrasena.
        $this->app['auth']->forgetGuards();
        $this->postJson('/api/auth/login', ['correo' => 'nuevo.qa@gymbros.test', 'password' => '!pendiente:x'])->assertUnauthorized();

        $this->como(self::ADMIN);
        $this->postJson('/api/usuarios', ['correo' => 'otro@gymbros.test', 'tipo_usuario' => 'Entrenador'] + $datos)
            ->assertUnprocessable()->assertJsonValidationErrors('id_empresas');
        $this->postJson('/api/usuarios', ['correo' => 'otro@gymbros.test', 'tipo_usuario' => 'Entrenador', 'id_empresas' => 2] + $datos)
            ->assertCreated()->assertJsonPath('data.tipo_usuario', 'Entrenador');
    }

    public function test_historial_de_usuario_y_su_alcance(): void
    {
        DB::table('historial_cambios')->insert(['id_empresas' => 1, 'id_usuarios' => self::EMPRESA_A, 'tabla_afectada' => 'usuarios',
            'id_registros' => self::USUARIO_A1, 'accion' => 'actualizar', 'datos_anteriores' => '{}', 'datos_nuevos' => '{}',
            'descripcion' => '[QA] Cambio de telefono', 'created_at' => now(), 'updated_at' => now()]);
        $this->como(self::EMPRESA_A);
        $this->getJson('/api/usuarios/'.self::USUARIO_A1.'/historial')->assertOk()
            ->assertJsonPath('data.0.descripcion', '[QA] Cambio de telefono')
            ->assertJsonPath('data.0.autor.nombre', '[QA] Empresa Usuario 2');
        $this->getJson('/api/usuarios/'.self::USUARIO_B1.'/historial')->assertForbidden();
        $this->como(self::ENTRENADOR_A);
        $this->getJson('/api/usuarios/'.self::USUARIO_A1.'/historial')->assertForbidden();
    }

    public function test_editar_y_retirar_ejercicio_solo_administrador(): void
    {
        DB::table('grupos_musculares')->insert(['id' => 1, 'descripcion' => 'Pecho', 'tipo' => 'pecho']);
        DB::table('ejercicios')->insert(['id' => 1, 'nombre' => 'Press', 'descripcion' => 'QA', 'tipo' => 'fuerza',
            'instrucciones' => 'QA', 'nivel' => 'intermedio', 'equipamiento' => 'Barra', 'estado' => true,
            'imagen_ejercicio' => 'ejercicios/a.webp', 'id_grupos_musculares' => 1]);

        $this->como(self::EMPRESA_A);
        $this->putJson('/api/ejercicios/1', ['nombre' => 'X'])->assertForbidden();
        $this->deleteJson('/api/ejercicios/1')->assertForbidden();

        $this->como(self::ADMIN);
        // El panel envia multipart como POST + _method=PUT.
        $this->post('/api/ejercicios/1', ['_method' => 'PUT', 'nombre' => 'Press inclinado', 'nivel' => 'Avanzado',
            'imagen_ejercicio' => UploadedFile::fake()->image('nueva.png')], ['Accept' => 'application/json'])
            ->assertOk()->assertJsonPath('data.nombre', 'Press inclinado')->assertJsonPath('data.nivel', 'avanzado');
        $ruta = DB::table('ejercicios')->where('id', 1)->value('imagen_ejercicio');
        $this->assertStringStartsWith('ejercicios/', $ruta);
        \Illuminate\Support\Facades\Storage::disk('public')->assertExists($ruta);
        $this->putJson('/api/ejercicios/1', ['nivel' => 'experto'])->assertUnprocessable()->assertJsonValidationErrors('nivel');
        $this->putJson('/api/ejercicios/1', [])->assertUnprocessable()->assertJsonValidationErrors('datos');
        $this->putJson('/api/ejercicios/999', ['nombre' => 'X'])->assertNotFound();
        $this->assertFalse((bool) $this->deleteJson('/api/ejercicios/1')->assertOk()->json('data.estado'));
        $this->assertDatabaseHas('ejercicios', ['id' => 1, 'estado' => 0]);
    }

    public function test_alta_de_alimento_valida_y_solo_administrador(): void
    {
        $alimento = ['nombre' => '[QA] Quinua', 'tipo' => 'cereal', 'calorias' => 120, 'proteinas' => 4.4,
            'carbohidratos' => 21.3, 'grasas' => 1.9, 'fibra' => 2.8];
        $this->como(self::EMPRESA_A);
        $this->postJson('/api/alimentos', $alimento)->assertForbidden();
        $this->como(self::ADMIN);
        $this->postJson('/api/alimentos', $alimento)->assertCreated()->assertJsonPath('data.nombre', '[QA] Quinua');
        $this->postJson('/api/alimentos', ['tipo' => 'metal', 'calorias' => -1] + $alimento)
            ->assertUnprocessable()->assertJsonValidationErrors(['tipo', 'calorias']);
        $this->assertDatabaseHas('alimentos', ['nombre' => '[QA] Quinua', 'activo' => 1]);
    }

    public function test_cambiar_contrasena_y_cerrar_otras_sesiones_revoca_tokens(): void
    {
        $this->app['auth']->forgetGuards();
        $login = fn () => $this->postJson('/api/auth/login', ['correo' => 'qa4@gymbros.test', 'password' => 'ClaveQa123!'])->assertOk()->json('data.token');
        $a = $login();
        $b = $login();
        $c = $login();
        $con = function (string $token, string $metodo, string $uri, array $datos = []) {
            $this->app['auth']->forgetGuards();

            return $this->json($metodo, $uri, $datos, ['Authorization' => 'Bearer '.$token]);
        };
        $con($a, 'POST', '/api/perfil/cerrar-otras-sesiones')->assertOk()->assertJsonPath('data.sesiones_cerradas', 2);
        $con($b, 'GET', '/api/auth/me')->assertUnauthorized();
        $con($a, 'GET', '/api/auth/me')->assertOk();

        $d = $login();
        $con($a, 'POST', '/api/perfil/cambiar-contrasena', ['password_actual' => 'incorrecta', 'password_nuevo' => 'NuevaClave2026',
            'password_confirmacion' => 'NuevaClave2026'])->assertUnprocessable()->assertJsonValidationErrors('password_actual');
        $con($a, 'POST', '/api/perfil/cambiar-contrasena', ['password_actual' => 'ClaveQa123!', 'password_nuevo' => 'corta',
            'password_confirmacion' => 'corta'])->assertUnprocessable()->assertJsonValidationErrors('password_nuevo');
        $con($a, 'POST', '/api/perfil/cambiar-contrasena', ['password_actual' => 'ClaveQa123!', 'password_nuevo' => 'NuevaClave2026',
            'password_confirmacion' => 'NuevaClave2026'])->assertOk();
        $con($d, 'GET', '/api/auth/me')->assertUnauthorized();
        $con($a, 'GET', '/api/auth/me')->assertOk();
        $this->assertTrue(Hash::check('NuevaClave2026', DB::table('usuarios')->where('id', self::USUARIO_A1)->value('password_hash')));
        $this->assertStringStartsWith('$2y$', DB::table('usuarios')->where('id', self::USUARIO_A1)->value('password_hash'));
        unset($c);
    }
}
