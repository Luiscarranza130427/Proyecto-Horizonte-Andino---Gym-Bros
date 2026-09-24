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
        Schema::create('ejercicios_rutina', function (Blueprint $table) {
            $table->id();
            $table->integer('dia');
            $table->integer('orden');
            $table->integer('series');
            $table->integer('repeticiones');
            $table->decimal('peso',6,2);
            $table->integer('descanso_segundos');
            $table->integer('tiempo_segundos');
            $table->text('notas');            
            $table->foreignId('id_rutinas')->constrained('rutinas')->onDelete('cascade');
            $table->foreignId('id_ejercicios')->constrained('ejercicios')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ejercicios_rutina');
    }
};
