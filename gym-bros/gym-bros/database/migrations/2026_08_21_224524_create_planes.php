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
        Schema::create('planes', function (Blueprint $table) {
            $table->id();
             $table->string('nombre', 100);
            $table->text('descripcion');
            $table->decimal('precio_original', 15, 2);
            $table->decimal('precio_inicial', 15, 2);
            $table->integer('duracion_dias');
            $table->integer('limite_usuarios');
            $table->boolean('activo')->default(false);
            $table->text('contenido')->nullable();
            $table->string('enlace_whatsapp', 300);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('planes');
    }
};
