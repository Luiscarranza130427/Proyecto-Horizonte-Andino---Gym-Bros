<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ConsultarPagosTest extends TestCase
{
    public function test_listado_detalle_ausentes_y_sin_escrituras(): void
    {
        $this->actuarComoAdministrador();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:', 'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:',DB::connection()->getDatabaseName());
        Schema::create('empresas', function (Blueprint $t) { $t->id(); $t->string('nombre'); });
        (require database_path('migrations/2026_08_21_224524_create_planes.php'))->up();
        Schema::create('suscripciones', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('id_empresas'); $t->unsignedBigInteger('id_planes');
            $t->date('fecha_inicio'); $t->date('fecha_fin'); $t->string('estado'); $t->boolean('renovacion_automatica');
        });
        (require database_path('migrations/2026_08_21_224540_create_pagos.php'))->up();
        DB::table('empresas')->insert(['id'=>1,'nombre'=>'Empresa QA']);
        DB::table('planes')->insert(['id'=>1,'nombre'=>'Plan QA','descripcion'=>'QA','precio_original'=>199,
            'precio_inicial'=>99,'duracion_dias'=>30,'limite_usuarios'=>50,'enlace_whatsapp'=>'https://wa.me/51912345678']);
        DB::table('suscripciones')->insert(['id'=>1,'id_empresas'=>1,'id_planes'=>1,'fecha_inicio'=>'2026-09-01',
            'fecha_fin'=>'2026-09-30','estado'=>'activa','renovacion_automatica'=>false]);
        DB::table('pagos')->insert(['id'=>1,'id_empresas'=>1,'id_suscripciones'=>1,'monto'=>199,'moneda'=>'PEN',
            'metodo_pago'=>'tarjeta','referencia'=>'QA-001','estado'=>'aprobado','fecha_pago'=>'2026-09-01 12:00:00']);
        $antes=DB::table('pagos')->get()->toJson();
        $lista=$this->getJson('/api/pagos')->assertOk()->assertJsonPath('data.0.empresa.nombre','Empresa QA')
            ->assertJsonPath('data.0.suscripcion.plan.nombre','Plan QA')->assertJsonPath('data.0.referencia','QA-001');
        $detalle=$this->getJson('/api/pagos/1')->assertOk();
        $this->assertSame($lista->json('data.0'),$detalle->json('data'));
        $this->getJson('/api/pagos/999')->assertNotFound()->assertExactJson(['message'=>'Pago no encontrado.']);
        $this->assertSame($antes,DB::table('pagos')->get()->toJson());
        // Simulate legacy orphan records without altering production constraints.
        Schema::disableForeignKeyConstraints();
        DB::table('planes')->delete();
        $this->getJson('/api/pagos/1')->assertOk()->assertJsonPath('data.suscripcion.plan',null);
        DB::table('suscripciones')->delete();
        DB::table('empresas')->delete();
        $this->getJson('/api/pagos/1')->assertOk()->assertJsonPath('data.suscripcion',null)->assertJsonPath('data.empresa',null);
        Schema::enableForeignKeyConstraints();
        DB::disconnect('sqlite');
    }
}
