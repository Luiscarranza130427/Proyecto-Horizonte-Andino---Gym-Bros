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
        Schema::create('pagos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_empresas')
            ->constrained('empresas')
            ->onDelete('cascade');
        $table->foreignId('id_suscripciones')
            ->constrained('suscripciones')
            ->onDelete('cascade');
        $table->decimal('monto', 10, 2);
        $table->string('moneda', 3)
            ->default('PEN');
        $table->string('metodo_pago', 50);
        $table->string('referencia', 255);
        $table->enum('estado', [
            'pendiente',
            'aprobado',
            'rechazado',
            'reembolsado'
        ])->default('pendiente');
        $table->dateTime('fecha_pago');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pagos');
    }
};
