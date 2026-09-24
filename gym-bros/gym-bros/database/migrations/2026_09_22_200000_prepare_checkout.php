<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::table('usuarios')->selectRaw('LOWER(TRIM(correo)) AS normalizado')->groupByRaw('LOWER(TRIM(correo))')->havingRaw('COUNT(*) > 1')->exists()) {
            throw new RuntimeException('Hay correos duplicados normalizados. Resolverlos sin borrar usuarios antes de migrar.');
        }
        Schema::table('usuarios', function (Blueprint $t) {
            $t->string('apodo',100)->nullable()->change();
            $t->enum('genero',['Varon','Mujer'])->nullable()->change();
            $t->enum('tipo_documento',['DNI','PASAPORTE','OTRO'])->nullable()->change();
            $t->string('numero_documento',12)->nullable()->change();
            $t->date('fecha_nacimiento')->nullable()->change();
            $t->date('inicio_suscripcion')->nullable()->change();
            $t->date('fin_suscripcion')->nullable()->change();
            $t->string('correo_normalizado',255)->storedAs('LOWER(TRIM(correo))')->unique();
        });
        Schema::create('ordenes_compra', function (Blueprint $t) {
            $t->id(); $t->uuid('uuid')->unique(); $t->foreignId('id_planes')->constrained('planes')->restrictOnDelete();
            $t->string('plan_nombre',100); $t->decimal('monto',10,2); $t->unsignedInteger('duracion_dias');
            $t->char('moneda',3)->default('PEN'); $t->text('comprador'); $t->text('empresa_datos');
            $t->string('estado',24)->default('pendiente')->index(); $t->uuid('idempotency_key')->unique();
            $t->char('request_hash',64); $t->string('preference_id')->nullable()->unique();
            $t->text('checkout_url')->nullable(); $t->string('payment_id')->nullable()->unique();
            $t->timestamp('expira_en'); $t->timestamp('aprobado_en')->nullable();
            $t->foreignId('id_empresas')->nullable()->unique()->constrained('empresas')->restrictOnDelete();
            $t->foreignId('id_usuarios')->nullable()->unique()->constrained('usuarios')->restrictOnDelete();
            $t->foreignId('id_suscripciones')->nullable()->unique()->constrained('suscripciones')->restrictOnDelete();
            $t->foreignId('id_pagos')->nullable()->unique()->constrained('pagos')->restrictOnDelete();
            $t->timestamp('correo_enviado_en')->nullable(); $t->char('password_token_hash',64)->nullable();
            $t->timestamp('password_token_expira')->nullable(); $t->timestamp('password_establecida_en')->nullable();
            $t->timestamps();
        });
        Schema::table('pagos', function (Blueprint $t) {
            $t->string('proveedor',30)->nullable(); $t->string('proveedor_payment_id')->nullable();
            $t->unique(['proveedor','proveedor_payment_id']);
            $t->string('preference_id')->nullable(); $t->uuid('external_reference')->nullable()->unique();
            $t->uuid('idempotency_key')->nullable()->unique(); $t->string('estado_detalle')->nullable();
            $t->timestamp('aprobado_en')->nullable(); $t->timestamp('reembolsado_en')->nullable();
            $t->decimal('monto_reembolsado',10,2)->default(0);
        });
        Schema::create('reembolsos_pago', function (Blueprint $t) {
            $t->id(); $t->foreignId('id_pago')->unique()->constrained('pagos')->restrictOnDelete();
            $t->foreignId('id_usuario')->constrained('usuarios')->restrictOnDelete();
            $t->uuid('idempotency_key')->unique(); $t->string('motivo',500); $t->string('estado',24)->default('pendiente');
            $t->string('proveedor_refund_id')->nullable()->unique(); $t->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['apodo','genero','tipo_documento','numero_documento','fecha_nacimiento'] as $campo) {
            if (DB::table('usuarios')->whereNull($campo)->exists()) {
                throw new RuntimeException('Completar perfiles antes de restaurar campos obligatorios. No se inventaran datos.');
            }
        }
        if (DB::table('ordenes_compra')->exists() || DB::table('reembolsos_pago')->exists()) {
            throw new RuntimeException('Existen compras o reembolsos: exportar y resolver la auditoria antes de revertir.');
        }
        Schema::dropIfExists('reembolsos_pago');
        Schema::dropIfExists('ordenes_compra');
        Schema::table('pagos', function (Blueprint $t) {
            $t->dropUnique(['proveedor','proveedor_payment_id']); $t->dropUnique(['external_reference']); $t->dropUnique(['idempotency_key']);
            $t->dropColumn(['proveedor','proveedor_payment_id','preference_id','external_reference','idempotency_key','estado_detalle','aprobado_en','reembolsado_en','monto_reembolsado']);
        });
        Schema::table('usuarios', function (Blueprint $t) {
            $t->dropUnique(['correo_normalizado']); $t->dropColumn('correo_normalizado');
            $t->string('apodo',100)->nullable(false)->change();
            $t->enum('genero',['Varon','Mujer'])->nullable(false)->change();
            $t->enum('tipo_documento',['DNI','PASAPORTE','OTRO'])->nullable(false)->change();
            $t->string('numero_documento',12)->nullable(false)->change();
            $t->date('fecha_nacimiento')->nullable(false)->change();
            $t->date('inicio_suscripcion')->nullable()->change();
            $t->date('fin_suscripcion')->nullable()->change();
        });
    }
};
