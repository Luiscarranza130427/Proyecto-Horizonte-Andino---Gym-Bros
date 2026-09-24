<?php

namespace Tests\Feature;

use App\Jobs\EnviarSolicitudDemo;
use App\Mail\SolicitudDemo;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{DB,Schema,Mail,Cache};
use Tests\TestCase;

class SolicitudDemoTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'cache.default'=>'array']);
        DB::purge('sqlite'); Cache::flush(); Mail::fake();
        (require database_path('migrations/2026_09_23_000000_create_solicitudes_demo.php'))->up();
        Schema::create('jobs', function (Blueprint $t) {
            $t->id(); $t->string('queue'); $t->longText('payload'); $t->unsignedTinyInteger('attempts');
            $t->unsignedInteger('reserved_at')->nullable(); $t->unsignedInteger('available_at'); $t->unsignedInteger('created_at');
        });
    }

    public function test_registra_encola_y_envia_a_destinatario_fijo(): void
    {
        $this->postJson('/api/solicitudes-demo', ['correo'=>'cliente@example.com','destinatario'=>'otro@example.com'])
            ->assertCreated()->assertExactJson(['data'=>['id'=>1,'estado'=>'pendiente','mensaje'=>'Solicitud registrada correctamente.']]);
        $this->assertDatabaseHas('solicitudes_demo',['id'=>1,'correo'=>'cliente@example.com','estado'=>'pendiente']);
        $this->assertDatabaseHas('jobs',['queue'=>'solicitudes-demo']);
        Mail::assertNothingSent();
        (new EnviarSolicitudDemo(1))->handle();
        Mail::assertSent(SolicitudDemo::class, fn ($mail) => $mail->hasTo('info@novawavedev.com') && !$mail->hasTo('otro@example.com'));
        $html = (new SolicitudDemo((object)['id'=>1,'correo'=>'<script>alert(1)</script>','created_at'=>'2026-09-22 12:00:00']))->render();
        $this->assertStringNotContainsString('<script>', $html);
    }

    public function test_validaciones(): void
    {
        foreach ([[],['correo'=>'incorrecto'],['correo'=>str_repeat('a',64).'@'.str_repeat('b',63).'.'.str_repeat('c',20).'.com']] as $data) {
            $this->postJson('/api/solicitudes-demo',$data)->assertUnprocessable()
                ->assertJsonPath('message','Los datos proporcionados no son válidos.')->assertJsonValidationErrors('correo');
        }
        $this->assertDatabaseCount('solicitudes_demo',0);
        $this->assertDatabaseCount('jobs',0);
    }

    public function test_limite_por_ip_expira_a_los_diez_minutos(): void
    {
        for ($i=0;$i<5;$i++) { $this->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertCreated(); }
        $this->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertStatus(429)
            ->assertJsonPath('message','Has realizado demasiadas solicitudes. Intenta nuevamente más tarde.');
        $this->withServerVariables(['REMOTE_ADDR'=>'192.0.2.2'])->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertCreated();
        $this->travel(11)->minutes();
        $this->withServerVariables(['REMOTE_ADDR'=>'127.0.0.1'])->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertCreated();
    }

    public function test_fallo_cola_no_deja_registro_parcial(): void
    {
        Schema::drop('jobs');
        $this->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertStatus(503)
            ->assertExactJson(['message'=>'No pudimos registrar la solicitud en este momento.']);
        $this->assertDatabaseCount('solicitudes_demo',0);
    }

    public function test_fallo_smtp_conserva_solicitud_y_oculta_error(): void
    {
        $this->postJson('/api/solicitudes-demo',['correo'=>'cliente@example.com'])->assertCreated();
        Mail::shouldReceive('mailer')->with('smtp')->andThrow(new \RuntimeException('secret smtp password'));
        try { (new EnviarSolicitudDemo(1))->handle(); $this->fail('Debe fallar el envio.'); }
        catch (\RuntimeException $e) {
            $this->assertSame('No se pudo enviar la notificacion de demostracion.', $e->getMessage());
            $this->assertNull($e->getPrevious());
        }
        $this->assertDatabaseCount('solicitudes_demo',1);
    }
}
