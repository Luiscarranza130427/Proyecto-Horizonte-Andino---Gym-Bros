<?php

namespace Tests\Feature;

use App\Jobs\{ProcesarRecuperacionPassword,EnviarRecuperacionPassword};
use App\Mail\RecuperacionPassword;
use App\Models\Usuario;
use App\Services\Auth\PasswordRecoveryService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{Auth,Cache,Crypt,DB,Hash,Mail,Password,Schema};
use Tests\TestCase;

class PasswordRecoveryTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'queue.connections.database.connection'=>null,
            'queue.failed.driver'=>'database-uuids','queue.failed.database'=>'sqlite',
            'cache.default'=>'array','auth.password_reset_url'=>'https://novawavedev.com/restablecer-contrasena']);
        DB::purge('sqlite'); Cache::flush(); Mail::fake();
        Schema::create('empresas', function (Blueprint $t) { $t->id(); });
        DB::table('empresas')->insert(['id'=>1]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        (require database_path('migrations/2026_09_22_195900_create_personal_access_tokens.php'))->up();
        Schema::create('password_reset_tokens', function (Blueprint $t) {
            $t->string('email')->primary(); $t->string('token'); $t->timestamp('created_at')->nullable();
        });
        Schema::create('jobs', function (Blueprint $t) {
            $t->id(); $t->string('queue'); $t->longText('payload'); $t->unsignedTinyInteger('attempts');
            $t->unsignedInteger('reserved_at')->nullable(); $t->unsignedInteger('available_at'); $t->unsignedInteger('created_at');
        });
        Schema::create('failed_jobs', function (Blueprint $t) {
            $t->id(); $t->string('uuid')->unique(); $t->text('connection'); $t->text('queue');
            $t->longText('payload'); $t->longText('exception'); $t->timestamp('failed_at')->useCurrent();
        });
        foreach ([1,2] as $id) {
            DB::table('usuarios')->insert(['id'=>$id,'nombres'=>'Prueba','apellidos'=>'Recuperacion','apodo'=>'QA','genero'=>'Varon',
                'correo'=>"persona$id@example.test",'password_hash'=>Hash::make('AnteriorClave123!'),'tipo_documento'=>'DNI',
                'numero_documento'=>'00123456','telefono'=>'999999999','fecha_registro'=>'2026-01-01',
                'fecha_nacimiento'=>'2000-01-01','tipo_usuario'=>'Empresa','estado'=>1,'id_empresas'=>1,
                'inicio_suscripcion'=>'2026-01-01','fin_suscripcion'=>'2027-01-01']);
        }
    }

    private function siguienteJob(): object
    {
        $registro = DB::table('jobs')->orderBy('id')->first();
        $this->assertNotNull($registro);
        $this->assertSame('recuperacion-password', $registro->queue);
        $this->assertStringNotContainsString('persona1@example.test',$registro->payload);
        $payload = json_decode($registro->payload, true);
        $job = unserialize(Crypt::decrypt($payload['data']['command']));
        DB::table('jobs')->where('id',$registro->id)->delete();
        return $job;
    }

    private function enlace(string $correo = 'persona1@example.test'): array
    {
        $this->postJson('/api/auth/forgot-password',['correo'=>$correo])->assertOk();
        $job = $this->siguienteJob();
        $this->assertInstanceOf(ProcesarRecuperacionPassword::class,$job);
        $job->handle(app(PasswordRecoveryService::class));
        $envio = $this->siguienteJob();
        $this->assertInstanceOf(EnviarRecuperacionPassword::class,$envio);
        $envio->handle();
        $mail = Mail::sent(RecuperacionPassword::class)->last();
        $this->assertTrue($mail->hasTo($correo));
        $this->assertStringStartsWith('https://novawavedev.com/restablecer-contrasena#', $mail->url);
        $this->assertNull(parse_url($mail->url,PHP_URL_QUERY));
        parse_str(parse_url($mail->url,PHP_URL_FRAGMENT),$query);
        return $query;
    }

    private function reset(array $link, array $extra = [])
    {
        return $this->postJson('/api/auth/reset-password',array_merge($link,[
            'password'=>'NuevaClaveSegura123!','password_confirmation'=>'NuevaClaveSegura123!',
        ],$extra));
    }

    public function test_respuesta_identica_y_solicitudes_encoladas_sin_buscar_cuenta(): void
    {
        $a=$this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertOk();
        $b=$this->postJson('/api/auth/forgot-password',['correo'=>'desconocido@example.test'])->assertOk();
        $this->assertSame($a->json(),$b->json());
        $this->assertSame('Si existe una cuenta con ese correo, recibirás las instrucciones para recuperar tu contraseña.', $a->json('message'));
        $this->assertDatabaseCount('jobs',2);
        $this->assertDatabaseCount('password_reset_tokens',0);
        Mail::assertNothingSent();
        $this->siguienteJob()->handle(app(PasswordRecoveryService::class));
        $this->siguienteJob()->handle(app(PasswordRecoveryService::class));
        $this->assertDatabaseCount('password_reset_tokens',1);
        $this->assertDatabaseCount('jobs',1);
    }

    public function test_reset_hash_revoca_sesiones_preserva_datos_y_permite_login(): void
    {
        $antes = (array) DB::table('usuarios')->where('id',1)->first();
        $usuario=Usuario::find(1);
        $uno=$usuario->createToken('vue',['sesion'])->plainTextToken;
        $usuario->createToken('flutter',['sesion']);
        Usuario::find(2)->createToken('otro',['sesion']);
        $link=$this->enlace();
        $hash=DB::table('password_reset_tokens')->value('token');
        $this->assertNotSame($link['token'],$hash);
        $this->assertTrue(Hash::check($link['token'],$hash));
        $this->reset($link)->assertOk()->assertJsonPath('message','Contraseña actualizada correctamente. Inicia sesión nuevamente.');
        $this->assertDatabaseCount('password_reset_tokens',0);
        $this->assertDatabaseCount('personal_access_tokens',1);
        $despues=(array) DB::table('usuarios')->where('id',1)->first();
        foreach (['password_hash','updated_at'] as $campo) { unset($antes[$campo],$despues[$campo]); }
        $this->assertSame($antes,$despues);
        Auth::forgetGuards();
        $this->withHeaders(['Authorization'=>'Bearer '.$uno])->getJson('/api/auth/me')->assertUnauthorized();
        $this->reset($link)->assertUnprocessable()->assertJsonValidationErrors('token');
        $this->postJson('/api/auth/login',['correo'=>$link['correo'],'password'=>'AnteriorClave123!'])->assertUnauthorized();
        $this->postJson('/api/auth/login',['correo'=>$link['correo'],'password'=>'NuevaClaveSegura123!'])->assertOk();
    }

    public function test_token_incorrecto_ajeno_vencido_y_renovacion(): void
    {
        $anterior=$this->enlace();
        $this->reset($anterior,['token'=>str_repeat('0',64)])->assertUnprocessable();
        $this->reset($anterior,['correo'=>'persona2@example.test'])->assertUnprocessable();
        $this->travel(61)->seconds();
        $nuevo=$this->enlace();
        $this->assertNotSame($anterior['token'],$nuevo['token']);
        $this->reset($anterior)->assertUnprocessable();
        $this->travel(61)->minutes();
        $this->reset($nuevo)->assertUnprocessable();
        $this->assertTrue(Hash::check('AnteriorClave123!',Usuario::find(1)->password_hash));
    }

    public function test_validacion_correo_y_password(): void
    {
        $this->postJson('/api/auth/forgot-password',[])->assertUnprocessable()->assertJsonValidationErrors('correo');
        $this->postJson('/api/auth/forgot-password',['correo'=>'invalido'])->assertUnprocessable();
        $this->postJson('/api/auth/forgot-password',['correo'=>str_repeat('a',256).'@example.com'])->assertUnprocessable();
        foreach (['corta1','abcdefghijklmnop','123456789012'] as $clave) {
            $this->reset(['correo'=>'persona1@example.test','token'=>str_repeat('a',64)],
                ['password'=>$clave,'password_confirmation'=>$clave])->assertUnprocessable()->assertJsonValidationErrors('password');
        }
        $this->reset(['correo'=>'persona1@example.test','token'=>str_repeat('a',64)],['password_confirmation'=>'distinta'])
            ->assertUnprocessable()->assertJsonValidationErrors('password');
    }

    public function test_intervalo_por_cuenta_y_limites_por_ip(): void
    {
        for ($i=0;$i<5;$i++) { $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertOk(); }
        $this->assertDatabaseCount('jobs',1);
        $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertStatus(429);
        for ($i=0;$i<5;$i++) { $this->reset(['correo'=>'persona1@example.test','token'=>str_repeat('a',64)])->assertUnprocessable(); }
        $this->reset(['correo'=>'persona1@example.test','token'=>str_repeat('a',64)])->assertStatus(429);
    }

    public function test_duplicados_no_generan_tokens_y_inactivos_no_se_activan(): void
    {
        DB::table('usuarios')->where('id',2)->update(['correo'=>'PERSONA1@example.test']);
        $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertOk();
        $this->siguienteJob()->handle(app(PasswordRecoveryService::class));
        $this->assertDatabaseCount('password_reset_tokens',0);
        $this->assertDatabaseCount('jobs',0);
        DB::table('usuarios')->where('id',2)->update(['correo'=>'persona2@example.test','estado'=>0]);
        $link=$this->enlace('persona2@example.test');
        $this->reset($link)->assertOk();
        $this->assertDatabaseHas('usuarios',['id'=>2,'estado'=>0]);
    }

    public function test_fallo_smtp_es_generico_payload_cifrado_y_reintento_util(): void
    {
        $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertOk();
        $this->siguienteJob()->handle(app(PasswordRecoveryService::class));
        $payload=DB::table('jobs')->value('payload');
        $job=$this->siguienteJob();
        Mail::shouldReceive('mailer')->with('smtp')->andThrow(new \RuntimeException('SMTP password secreto'));
        try { $job->handle(); $this->fail('Debe fallar SMTP.'); }
        catch (\RuntimeException $e) {
            $this->assertSame('No se pudo enviar la recuperacion.', $e->getMessage());
            $this->assertNull($e->getPrevious());
            app('queue.failer')->log('database','recuperacion-password',$payload,$e);
        }
        $fallo=DB::table('failed_jobs')->first();
        $this->assertStringNotContainsString('SMTP password secreto',$fallo->exception);
        $this->assertStringNotContainsString('persona1@example.test',$fallo->payload);
        $this->assertSame($payload,$fallo->payload);
        Mail::swap(new \Illuminate\Mail\MailManager($this->app));
        Mail::fake(); $job->handle();
        Mail::assertSent(RecuperacionPassword::class);
    }

    public function test_error_de_revocacion_revierte_password_y_token(): void
    {
        $link=$this->enlace();
        Schema::drop('personal_access_tokens');
        $this->reset($link)->assertStatus(503)->assertJsonMissingPath('exception');
        $this->assertTrue(Hash::check('AnteriorClave123!',Usuario::find(1)->password_hash));
        $this->assertTrue(Password::broker('usuarios')->tokenExists(Usuario::find(1),$link['token']));
    }

    public function test_host_y_redireccion_cliente_no_controlan_enlace_y_https_produccion(): void
    {
        $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test','url'=>'https://evil.test'],
            ['Host'=>'evil.test'])->assertOk();
        $this->siguienteJob()->handle(app(PasswordRecoveryService::class));
        $this->siguienteJob()->handle();
        $mail=Mail::sent(RecuperacionPassword::class)->first();
        $this->assertStringNotContainsString('evil.test',$mail->url);
        $this->assertStringNotContainsString('<script>',(new RecuperacionPassword('https://example.com/?q=<script>'))->render());
        $this->app->instance('env','production');
        $this->postJson('/api/auth/forgot-password',['correo'=>'persona1@example.test'])->assertStatus(400);
    }
}
