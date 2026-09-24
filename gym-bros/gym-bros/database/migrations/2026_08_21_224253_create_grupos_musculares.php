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
        Schema::create('grupos_musculares', function (Blueprint $table) {
            $table->id();
            $table->text('descripcion')->nullable();
            $table->boolean('estado')->default(true);
            $table->enum('tipo',['pecho','espalda','hombros','biceps','triceps','cuadriceps','isquitiobiales','gluteos','pantorrillas',
                            'abdomen','antebrazos','trapecios','serratos','oblicuos','lumbares','aductores','abductores']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grupos_musculares');
    }
};
