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
        Schema::create('comidas', function (Blueprint $table) {
            $table->id();
            $table->string('nombre',150);
            $table->enum('tipo',['desayuno','media_manana','almuerzo','media_tarde','cena','snack','otro']);
            $table->integer('orden');
            $table->time('hora_sugerida');
            $table->text('notas');
            $table->foreignId('id_planes_alimentacion')->constrained('planes_alimentacion')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('comidas');
    }
};
