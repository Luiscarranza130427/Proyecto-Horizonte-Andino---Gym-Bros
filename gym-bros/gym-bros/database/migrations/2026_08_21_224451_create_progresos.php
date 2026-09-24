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
        Schema::create('progresos', function (Blueprint $table) {
            $table->id();
            $table->date('fecha');
            $table->decimal('peso',6,2);
            $table->decimal('altura',5,2);
            $table->decimal('porcentaje_grasa',5,2);
            $table->decimal('masa_muscular',6,2);
            $table->decimal('cintura',6,2);
            $table->decimal('pecho',6,2);
            $table->decimal('brazo',6,2);
            $table->decimal('muslo',6,2);
            $table->decimal('cadera',6,2);
            $table->text('notas');
            $table->foreignId('id_usuarios')->constrained('usuarios')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('progresos');
    }
};
