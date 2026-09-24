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
        Schema::create('sensaciones', function (Blueprint $table) {
            $table->id();
            $table->date('fecha');
            $table->integer('energia');
            $table->integer('dificultad');
            $table->integer('fatiga');
            $table->integer('dolor');
            $table->text('comentario');
            $table->foreignId('id_usuarios')->constrained('usuarios')->onDelete('cascade');
            $table->foreignId('id_rutinas')->constrained('rutinas')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sensaciones');
    }
};
