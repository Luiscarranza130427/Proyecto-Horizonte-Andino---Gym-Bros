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
        Schema::create('notificaciones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_empresas')
                ->nullable()
                ->constrained('empresas')
                ->nullOnDelete();

            $table->foreignId('id_usuarios')
                ->nullable()
                ->constrained('usuarios')
                ->nullOnDelete();

            $table->enum('tipo', [
                'recordatorio',
                'rutina',
                'alimentacion',
                'suscripcion',
                'sistema',
                'otro'
            ]);

            $table->string('titulo', 150);
            $table->text('mensaje');
            $table->dateTime('fecha_envio');

            $table->boolean('leida')->default(false);
            $table->boolean('enviada')->default(false); 
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notificaciones');
    }
};
