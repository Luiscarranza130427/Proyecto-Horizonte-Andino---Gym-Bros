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
        Schema::create('ejercicios', function (Blueprint $table) {
            $table->id();
            $table->string('nombre',100);
            $table->text('descripcion')->nullable();
            $table->enum('tipo',['fuerza','cardio','flexibilidad','equilibrio']);
            $table->text('instrucciones');
            $table->enum('nivel',['principiante','intermedio','avanzado']);
            $table->string('equipamiento',100);
            $table->boolean('estado')->default(false);
            $table->string('enlace_video',350)->nullable();
            $table->string('imagen_ejercicio',350);
            $table->foreignId('id_grupos_musculares')->constrained('grupos_musculares')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ejercicios');
    }
};
