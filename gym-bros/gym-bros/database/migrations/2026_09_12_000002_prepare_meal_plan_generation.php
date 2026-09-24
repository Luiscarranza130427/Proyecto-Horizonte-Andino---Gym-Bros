<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('alimentos', function (Blueprint $table) {
            $table->enum('base_unidad', ['gramos', 'mililitros'])->nullable();
            $table->string('estado_preparacion', 100)->nullable();
            $table->decimal('gramos_por_unidad', 8, 2)->nullable();
            $table->decimal('densidad_g_ml', 8, 4)->nullable();
            $table->text('fuente_nutricional')->nullable();
            $table->boolean('nutricion_verificada')->default(false);
            $table->boolean('restricciones_verificadas')->default(false);
            $table->enum('grupo_menu', ['proteina', 'carbohidrato', 'grasa', 'fruta', 'verdura'])->nullable();
            $table->json('tipos_comida')->nullable();
            $table->decimal('porcion_min', 8, 2)->nullable();
            $table->decimal('porcion_max', 8, 2)->nullable();
            $table->decimal('paso_porcion', 8, 2)->nullable();
        });
        Schema::table('preferencias_alimentarias', function (Blueprint $table) {
            $table->enum('tipo', ['preferido', 'rechazado'])->nullable();
        });
        Schema::create('restricciones_alimentarias', function (Blueprint $table) {
            $table->id();
            $table->string('codigo', 80)->unique();
            $table->string('nombre', 150);
            $table->timestamps();
        });
        Schema::create('alimento_restriccion', function (Blueprint $table) {
            $table->foreignId('id_alimentos')->constrained('alimentos')->cascadeOnDelete();
            $table->foreignId('id_restricciones_alimentarias')->constrained('restricciones_alimentarias', indexName: 'alimento_restriccion_fk')->restrictOnDelete();
            $table->primary(['id_alimentos', 'id_restricciones_alimentarias'], 'alimento_restriccion_pk');
        });
        Schema::create('usuario_restriccion_alimentaria', function (Blueprint $table) {
            $table->foreignId('id_usuarios')->constrained('usuarios')->cascadeOnDelete();
            $table->foreignId('id_restricciones_alimentarias')->constrained('restricciones_alimentarias', indexName: 'usuario_restriccion_fk')->restrictOnDelete();
            $table->enum('tipo', ['alergia', 'intolerancia']);
            $table->primary(['id_usuarios', 'id_restricciones_alimentarias', 'tipo'], 'usuario_restriccion_pk');
        });
        Schema::create('perfiles_alimentarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_usuarios')->unique()->constrained('usuarios')->cascadeOnDelete();
            $table->enum('sexo_calculo', ['masculino', 'femenino']);
            $table->boolean('embarazo');
            $table->boolean('lactancia');
            $table->boolean('requiere_plan_clinico');
            $table->boolean('apto_plan_general');
            $table->string('revision_profesional', 200);
            $table->date('revisado_en');
            $table->timestamps();
        });
        Schema::table('planes_alimentacion', function (Blueprint $table) {
            $table->foreignId('id_evaluaciones_fisicas')->nullable()->constrained('evaluaciones_fisicas')->nullOnDelete();
            $table->json('calculo')->nullable();
        });
        Schema::table('comidas', function (Blueprint $table) {
            $table->date('fecha')->nullable();
            $table->unsignedSmallInteger('dia')->nullable();
            $table->unique(['id_planes_alimentacion', 'dia', 'orden'], 'plan_dia_orden_unique');
        });
        Schema::table('comida_alimentos', function (Blueprint $table) {
            $table->json('detalle_nutricional')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('comida_alimentos', fn (Blueprint $table) => $table->dropColumn('detalle_nutricional'));
        Schema::table('comidas', function (Blueprint $table) {
            $table->dropUnique('plan_dia_orden_unique');
            $table->dropColumn(['fecha', 'dia']);
        });
        Schema::table('planes_alimentacion', function (Blueprint $table) {
            $table->dropConstrainedForeignId('id_evaluaciones_fisicas');
            $table->dropColumn('calculo');
        });
        Schema::dropIfExists('perfiles_alimentarios');
        Schema::dropIfExists('usuario_restriccion_alimentaria');
        Schema::dropIfExists('alimento_restriccion');
        Schema::dropIfExists('restricciones_alimentarias');
        Schema::table('preferencias_alimentarias', fn (Blueprint $table) => $table->dropColumn('tipo'));
        Schema::table('alimentos', fn (Blueprint $table) => $table->dropColumn([
            'base_unidad', 'estado_preparacion', 'gramos_por_unidad', 'densidad_g_ml',
            'fuente_nutricional', 'nutricion_verificada', 'restricciones_verificadas',
            'grupo_menu', 'tipos_comida', 'porcion_min', 'porcion_max', 'paso_porcion',
        ]));
    }
};
