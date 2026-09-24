<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('evaluaciones_fisicas', function (Blueprint $table) {
            $table->id();
            $table->enum('nivel_experiencia', ['1a3meses','4a8anos','1ano','mas1ano','2anos','3anosamas']);
            $table->enum('actividad_diaria', ['sedentario','activo_ligero','moderadamente_activo','muy_activo']);
            $table->enum('objetivo',['perdida_peso','ganancia_muscular','resistencia','recomposicion','aumento_fuerza','salud']);
            $table->integer('edad');
            $table->decimal('peso', 6,2);
            $table->decimal('altura', 5,2);
            $table->decimal('porcentaje_grasa', 5,2);
            $table->decimal('masa_muscular', 6,2);
            $table->decimal('cintura', 6,2);
            $table->decimal('pecho', 6,2);
            $table->decimal('brazo', 6,2);
            $table->decimal('muslo', 6,2);
            $table->decimal('cadera', 6,2);
            $table->integer('dias_semana');
            $table->enum('eleccion_dias',['Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo']);
            $table->integer('tiempo_sesion_min');
            $table->enum('restricciones',['sin-restricciones','manco','cojo','paralitico','movilidad-reducida','amputacion-de-extremidad','silla-de-ruedas','uso-de-muletas','uso-de-baston','uso-de-andador','limitacion-de-brazos','limitacion-de-piernas','problemas-de-equilibrio','problemas-de-coordinacion','lesion-reciente','cirugia-reciente','dolor-musculoesqueletico','limitacion-cardiovascular','limitacion-respiratoria','discapacidad-visual','discapacidad-auditiva']);
            $table->date('fecha_evaluacion');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('evaluaciones_fisicas');
    }
};
