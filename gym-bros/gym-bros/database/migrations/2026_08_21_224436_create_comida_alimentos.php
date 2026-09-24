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
        Schema::create('comida_alimentos', function (Blueprint $table) {
            $table->id();
            $table->decimal('cantidad',8,2);
            $table->enum('unidad',['gramos','mililitros','unidad']);
            $table->text('notas');
            $table->foreignId('id_comidas')->constrained('comidas')->onDelete('cascade');
            $table->foreignId('id_alimentos')->constrained('alimentos')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('comida_alimentos');
    }
};
