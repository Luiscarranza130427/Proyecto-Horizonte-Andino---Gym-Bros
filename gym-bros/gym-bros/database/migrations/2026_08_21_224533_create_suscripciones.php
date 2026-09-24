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
        Schema::create('suscripciones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_empresas')
                ->constrained('empresas')
                ->restrictOnDelete();
        $table->foreignId('id_planes')
                ->constrained('planes')
                ->restrictOnDelete();
        $table->date('fecha_inicio');
        $table->date('fecha_fin');
        $table->enum('estado', [
                'pendiente',
                'activa',
                'vencida',
                'cancelada',
                'suspendida'
            ])->default('pendiente');
        $table->boolean('renovacion_automatica')
                ->default(false);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('suscripciones');
    }
};
