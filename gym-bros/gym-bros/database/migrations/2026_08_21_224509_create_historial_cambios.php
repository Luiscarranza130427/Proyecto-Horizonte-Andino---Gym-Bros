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
        Schema::create('historial_cambios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_empresas')
                ->constrained('empresas')
                ->restrictOnDelete();

            $table->foreignId('id_usuarios')
                ->constrained('usuarios')
                ->restrictOnDelete();

            $table->string('tabla_afectada', 100);
            $table->integer('id_registros');

            $table->enum('accion', [
                'crear',
                'actualizar',
                'eliminar',
                'activar',
                'desactivar'
            ]);
            $table->json('datos_anteriores');
            $table->json('datos_nuevos');
            $table->text('descripcion');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('historial_cambios');
    }
};
