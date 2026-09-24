<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('preferencias_usuario', function (Blueprint $table) {
            $table->foreignId('id_usuarios')->primary()->constrained('usuarios')->cascadeOnDelete();
            $table->json('preferencias');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('preferencias_usuario');
    }
};
