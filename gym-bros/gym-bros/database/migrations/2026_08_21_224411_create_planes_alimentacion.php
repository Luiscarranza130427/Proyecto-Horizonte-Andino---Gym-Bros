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
        Schema::create('planes_alimentacion', function (Blueprint $table) {
            $table->id();
            $table->string('nombre',150);
            $table->text('descripcion');
            $table->string('objetivo',100);
            $table->decimal('calorias_objetivo',6,2);
            $table->decimal('proteinas_objetivo',6,2);
            $table->decimal('carbohidratos_objetivo',6,2);
            $table->decimal('grasas_objetivo',6,2);
            $table->date('fecha_inicio');
            $table->date('fecha_fin');
            $table->boolean('estado')->default(true);
            $table->foreignId('id_usuarios')->constrained('usuarios')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('planes_alimentacion');
    }
};
