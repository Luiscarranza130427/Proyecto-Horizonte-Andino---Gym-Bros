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
Schema::create('empresa_ejercicio', function (Blueprint $table) {
    $table->id();
    $table->foreignId('id_empresas') ->constrained('empresas') ->onDelete('cascade');
    $table->foreignId('id_ejercicios') ->constrained('ejercicios') ->onDelete('cascade');
    $table->boolean('estado')->default(true);
    $table->unique(['id_empresas', 'id_ejercicios']);
    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('empresa_ejercicio');
    }
};
