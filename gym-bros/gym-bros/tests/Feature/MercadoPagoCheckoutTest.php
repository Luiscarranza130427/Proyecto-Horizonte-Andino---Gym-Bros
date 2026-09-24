<?php

namespace Tests\Feature;

use App\Jobs\{EnviarConfirmacionCompra,ProcesarPagoMercadoPago};
use App\Mail\ConfirmacionCompra;
use App\Models\{OrdenCompra,Usuario};
use App\Services\Pagos\CheckoutService;
use Carbon\{Carbon,CarbonImmutable};
use Illuminate\Support\Facades\{DB,Hash,Http,Mail,Queue,Schema};
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MercadoPagoCheckoutTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'mercadopago.enabled'=>true,
            'mercadopago.access_token'=>'FAKE-TEST','mercadopago.webhook_secret'=>'test-secret',
            'mercadopago.notification_url'=>'https://api.example.test/api/webhooks/mercado-pago',
            'mercadopago.frontend_url'=>'https://front.example.test','mercadopago.live_mode'=>false,
            'mercadopago.logo'=>'email/notificaciones-fondo.webp','app.url'=>'https://api.example.test']);
        DB::purge('sqlite');
        $this->assertSame(':memory:',DB::connection()->getDatabaseName());
        Carbon::setTestNow('2026-09-22 15:00:00'); CarbonImmutable::setTestNow('2026-09-22 15:00:00');
        foreach (['2026_08_21_224135_create_empresas.php','2026_08_21_224236_create_usuarios.php',
            '2026_08_21_224524_create_planes.php','2026_08_21_224533_create_suscripciones.php',
            '2026_08_21_224540_create_pagos.php','2026_09_22_195900_create_personal_access_tokens.php','2026_09_22_200000_prepare_checkout.php'] as $file) {
            (require database_path('migrations/'.$file))->up();
        }
        DB::table('planes')->insert(['id'=>1,'nombre'=>'Plan QA','descripcion'=>'QA','precio_original'=>199,
            'precio_inicial'=>99.90,'duracion_dias'=>30,'limite_usuarios'=>50,'activo'=>true,'enlace_whatsapp'=>'https://example.test']);
        Http::preventStrayRequests(); Queue::fake(); Mail::fake();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow(); CarbonImmutable::setTestNow(); DB::disconnect('sqlite'); parent::tearDown();
    }

    private function datos(): array
    {
        return ['plan_id'=>1,'usuario'=>['nombres'=>'QA','apellidos'=>'Prueba','correo'=>' COMPRADOR@example.test ','telefono'=>'912345678',
            'apodo'=>'QA comprador','genero'=>'Varon','tipo_documento'=>'DNI','numero_documento'=>'00123456',
            'fecha_registro'=>'2026-09-21','fecha_nacimiento'=>'1998-04-15','tipo_usuario'=>'Empresa'],
            'empresa'=>['nombre'=>'Gym QA','nombre_gerente'=>'QA','telefono'=>'987654321','correo'=>'empresa@example.test'],
            'monto'=>0.01,'moneda'=>'USD','duracion_dias'=>9999,'estado'=>'aprobado'];
    }

    public function test_checkout_exige_perfil_completo_y_rechaza_roles_y_fechas_invalidos(): void
    {
        $this->withoutMiddleware(\Illuminate\Routing\Middleware\ThrottleRequests::class);
        foreach (array_keys($this->datos()['usuario']) as $campo) {
            $datos = $this->datos();
            unset($datos['usuario'][$campo]);
            $this->postJson('/api/checkout/mercado-pago', $datos, ['Idempotency-Key'=>(string) Str::uuid()])
                ->assertUnprocessable()->assertJsonValidationErrors('usuario.'.$campo);
        }
        foreach (['tipo_usuario'=>'Administrador','genero'=>'invalido','tipo_documento'=>'invalido',
            'numero_documento'=>str_repeat('1',13),'fecha_registro'=>'2026-09-23','fecha_nacimiento'=>'2026-09-22'] as $campo=>$valor) {
            $datos = $this->datos();
            $datos['usuario'][$campo] = $valor;
            $this->postJson('/api/checkout/mercado-pago', $datos, ['Idempotency-Key'=>(string) Str::uuid()])
                ->assertUnprocessable()->assertJsonValidationErrors('usuario.'.$campo);
        }
        $this->assertDatabaseCount('ordenes_compra',0);
        Http::assertNothingSent();
    }

    private function orden(): OrdenCompra
    {
        $this->fake(['api.mercadopago.com/checkout/preferences'=>Http::response(['id'=>'pref-1','init_point'=>'https://www.mercadopago.com.pe/checkout/test'])]);
        $this->postJson('/api/checkout/mercado-pago',$this->datos(),['Idempotency-Key'=>(string) Str::uuid()])->assertCreated();
        return OrdenCompra::firstOrFail();
    }

    private function pago(OrdenCompra $orden, array $extra = []): array
    {
        return array_merge(['id'=>123,'external_reference'=>$orden->uuid,'currency_id'=>'PEN','transaction_amount'=>99.9,
            'live_mode'=>false,'status'=>'approved','date_approved'=>now()->toIso8601String(),
            'payment_type_id'=>'debit_card','status_detail'=>'accredited'],$extra);
    }

    private function aprobar(): OrdenCompra
    {
        $orden = $this->orden();
        $this->fake(['api.mercadopago.com/v1/payments/123'=>Http::response($this->pago($orden))]);
        app(CheckoutService::class)->procesar('123');
        return $orden->fresh();
    }

    public function test_snapshot_idempotencia_estado_seguro_y_sin_activacion_por_redirect(): void
    {
        $orden=$this->orden();
        $this->assertSame('99.90',$orden->monto);
        $this->assertSame(30,$orden->duracion_dias);
        $this->assertDatabaseCount('empresas',0); $this->assertDatabaseCount('usuarios',0);
        $this->assertDatabaseCount('suscripciones',0); $this->assertDatabaseCount('pagos',0);
        $this->assertStringNotContainsString('comprador@example.test',DB::table('ordenes_compra')->value('comprador'));
        $this->assertArrayNotHasKey('password',$orden->comprador);
        DB::table('planes')->update(['precio_inicial'=>500]);
        $this->postJson('/api/checkout/mercado-pago',$this->datos(),['Idempotency-Key'=>$orden->idempotency_key])->assertCreated();
        $this->assertDatabaseCount('ordenes_compra',1);
        $r=$this->getJson('/api/checkout/'.$orden->uuid.'/estado?status=approved')->assertOk()->assertJsonPath('data.monto','99.90');
        $this->assertStringNotContainsString('correo',$r->getContent());
        $this->assertDatabaseCount('empresas',0);
        Http::assertSent(fn ($r)=>$r['items'][0]['unit_price'] === 99.9 && $r['items'][0]['currency_id'] === 'PEN');
    }

    public function test_inactivo_configuracion_y_validaciones(): void
    {
        Http::fake();
        DB::table('planes')->update(['activo'=>false]);
        $this->postJson('/api/checkout/mercado-pago',$this->datos(),['Idempotency-Key'=>(string) Str::uuid()])->assertUnprocessable();
        $this->assertDatabaseCount('ordenes_compra',0);
        config(['mercadopago.enabled'=>false]);
        $this->postJson('/api/checkout/mercado-pago',$this->datos())->assertStatus(503);
        Http::assertNothingSent();
    }

    public function test_webhook_firma_timestamp_cuerpo_y_cola(): void
    {
        $body=['type'=>'payment','data'=>['id'=>'123']];
        $this->postJson('/api/webhooks/mercado-pago?data.id=123',$body)->assertUnauthorized();
        $ts=now()->timestamp;
        $hash=hash_hmac('sha256',"id:123;request-id:qa-request;ts:$ts;",'test-secret');
        $headers=['x-request-id'=>'qa-request','x-signature'=>"ts=$ts,v1=$hash"];
        $this->postJson('/api/webhooks/mercado-pago?data.id=123',$body,$headers)->assertOk();
        Queue::assertPushed(ProcesarPagoMercadoPago::class);
        $this->postJson('/api/webhooks/mercado-pago?data.id=123',['type'=>'payment','data'=>['id'=>'999']],$headers)->assertUnprocessable();
        $this->travel(6)->minutes();
        $this->postJson('/api/webhooks/mercado-pago?data.id=123',$body,$headers)->assertUnauthorized();
        $this->assertDatabaseCount('empresas',0);
    }

    public function test_aprobacion_unica_duracion_y_enlace_password_un_solo_uso(): void
    {
        $orden=$this->aprobar();
        app(CheckoutService::class)->procesar('123');
        foreach (['empresas','usuarios','suscripciones','pagos'] as $table) { $this->assertDatabaseCount($table,1); }
        $usuario=Usuario::firstOrFail();
        $this->assertSame('Empresa',$usuario->tipo_usuario);
        $this->assertDatabaseHas('empresas', ['id'=>$usuario->id_empresas,
            'logo'=>config('mercadopago.logo'),'color_1'=>'#E50914','color_2'=>'#111111',
            'estado'=>1,'fecha_registro'=>'2026-09-22']);
        $this->assertNotEmpty(Hash::info($usuario->password_hash)['algoName']);
        foreach (['apodo','genero','tipo_documento','numero_documento','fecha_registro','fecha_nacimiento'] as $campo) {
            $this->assertDatabaseHas('usuarios', ['id'=>$usuario->id, $campo=>$this->datos()['usuario'][$campo]]);
        }
        $this->assertNull($usuario->fin_suscripcion);
        $this->assertDatabaseHas('suscripciones',['fecha_inicio'=>'2026-09-22','fecha_fin'=>'2026-10-22','renovacion_automatica'=>false]);
        (new EnviarConfirmacionCompra($orden->id))->handle();
        $url=null;
        Mail::assertSent(ConfirmacionCompra::class,function ($mail) use (&$url) {
            parse_str(parse_url($mail->acceso,PHP_URL_QUERY),$q); $url=$q['url'];
            $this->assertStringNotContainsString('FAKE-TEST',$mail->render());
            return true;
        });
        $payload=['password'=>'NuevaClaveSegura123','password_confirmation'=>'NuevaClaveSegura123'];
        $this->postJson($url,$payload)->assertOk();
        $this->assertTrue(Hash::check($payload['password'],$usuario->fresh()->password_hash));
        $this->postJson($url,$payload)->assertForbidden();
        $this->postJson('/api/checkout/login',['correo'=>'comprador@example.test','password'=>$payload['password']])->assertOk()->assertJsonStructure(['data'=>['token']]);
    }

    public function test_rechazado_y_monto_moneda_invalidos_no_activan(): void
    {
        $orden=$this->orden();
        $this->fake(['api.mercadopago.com/v1/payments/123'=>Http::response($this->pago($orden,['status'=>'rejected']))]);
        app(CheckoutService::class)->procesar('123');
        $this->assertSame('rechazado',$orden->fresh()->estado);
        foreach ([['currency_id'=>'USD'],['transaction_amount'=>1],['live_mode'=>true],['external_reference'=>(string) Str::uuid()]] as $extra) {
            $this->fake(['api.mercadopago.com/v1/payments/123'=>Http::response($this->pago($orden,$extra))]);
            try { app(CheckoutService::class)->procesar('123'); $this->fail('Debe rechazar el pago.'); }
            catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) { $this->assertSame(422,$e->getStatusCode()); }
        }
        $this->assertDatabaseCount('empresas',0);
    }

    public function test_reembolso_autorizacion_cinco_dias_idempotencia(): void
    {
        $orden=$this->aprobar();
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',['motivo'=>'QA'])->assertUnauthorized();
        $usuario=Usuario::first(); Sanctum::actingAs($usuario,['pagos:reembolsar']);
        $usuario->id_empresas=999;
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',['motivo'=>'QA'])->assertForbidden();
        $usuario->id_empresas=$orden->id_empresas;
        Carbon::setTestNow('2026-09-28 15:00:00'); CarbonImmutable::setTestNow('2026-09-28 15:00:00');
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',['motivo'=>'QA'])->assertUnprocessable();
        Carbon::setTestNow('2026-09-27 15:00:00'); CarbonImmutable::setTestNow('2026-09-27 15:00:00');
        $this->fake([
            'api.mercadopago.com/v1/payments/123'=>Http::sequence()->push($this->pago($orden))->push($this->pago($orden,['status'=>'refunded','transaction_amount_refunded'=>99.9])),
            'api.mercadopago.com/v1/payments/123/refunds'=>Http::response(['id'=>456,'payment_id'=>123,'status'=>'approved','amount'=>99.9]),
        ]);
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',['motivo'=>'QA'])->assertOk();
        $this->assertDatabaseHas('pagos',['estado'=>'reembolsado']);
        $this->assertDatabaseHas('suscripciones',['estado'=>'cancelada']);
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',['motivo'=>'QA'])->assertStatus(409);
    }

    public function test_fallo_correo_no_revierte_compra(): void
    {
        $orden=$this->aprobar();
        Mail::shouldReceive('to')->once()->andThrow(new \RuntimeException('QA'));
        try { (new EnviarConfirmacionCompra($orden->id))->handle(); } catch (\RuntimeException) {}
        $this->assertSame('aprobado',$orden->fresh()->estado);
        $this->assertNull($orden->fresh()->correo_enviado_en);
        $this->assertDatabaseCount('pagos',1);
    }

    public function test_migracion_reversible_y_correo_normalizado_unico(): void
    {
        $migration=require database_path('migrations/2026_09_22_200000_prepare_checkout.php');
        $migration->down();
        $this->assertFalse(Schema::hasTable('ordenes_compra'));
        $this->assertFalse(Schema::hasColumn('usuarios','correo_normalizado'));
        $migration->up();
        $this->assertTrue(Schema::hasTable('ordenes_compra'));
    }

    private function fake(array $responses): void
    {
        Http::swap(new \Illuminate\Http\Client\Factory());
        Http::preventStrayRequests();
        Http::fake($responses);
    }

    public function test_fallo_proveedor_conserva_orden_pendiente_y_reintento(): void
    {
        $key=(string) Str::uuid();
        $this->fake(['api.mercadopago.com/checkout/preferences'=>Http::response(['message'=>'SECRET-PROVIDER-DATA'],500)]);
        $r=$this->postJson('/api/checkout/mercado-pago',$this->datos(),['Idempotency-Key'=>$key])->assertStatus(502);
        $this->assertStringNotContainsString('SECRET-PROVIDER-DATA',$r->getContent());
        $this->assertDatabaseHas('ordenes_compra',['estado'=>'pendiente']);
        $this->assertDatabaseCount('empresas',0);
        $this->fake(['api.mercadopago.com/checkout/preferences'=>Http::response(['id'=>'pref-1','init_point'=>'https://www.mercadopago.com.pe/checkout/test'])]);
        $this->postJson('/api/checkout/mercado-pago',$this->datos(),['Idempotency-Key'=>$key])->assertCreated();
        $this->assertDatabaseCount('ordenes_compra',1);
        $datos=$this->datos(); $datos['empresa']['nombre']='Otro';
        $this->postJson('/api/checkout/mercado-pago',$datos,['Idempotency-Key'=>$key])->assertStatus(409);
    }

    public function test_token_real_sanctum_y_correo_unico(): void
    {
        $orden=$this->aprobar();
        $usuario=Usuario::firstOrFail();
        $token=$usuario->createToken('QA',['pagos:reembolsar'])->plainTextToken;
        $this->postJson('/api/pagos/'.$orden->id_pagos.'/reembolso',[],['Authorization'=>'Bearer '.$token])->assertUnprocessable();
        $this->postJson('/api/checkout/'.$orden->uuid.'/password?signature=falsa',[
            'password'=>'ClaveValida1234','password_confirmation'=>'ClaveValida1234',
        ])->assertForbidden();
        try {
            $copia=$usuario->replicate(['correo_normalizado']);
            $copia->correo=' COMPRADOR@EXAMPLE.TEST ';
            $copia->save();
            $this->fail('No debe aceptar correo duplicado.');
        } catch (\Illuminate\Database\QueryException) {
            $this->assertDatabaseCount('usuarios',1);
        }
    }
}
