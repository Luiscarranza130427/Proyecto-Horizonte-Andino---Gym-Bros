<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('solicitudes_demo', function (Blueprint $table) {
            $table->id();
            $table->string('correo', 150);
            $table->ipAddress('ip')->nullable();
            $table->text('user_agent')->nullable();
            $table->string('estado', 30)->default('pendiente');
            $table->timestamps();
        });
    }

    public function down(): void { Schema::dropIfExists('solicitudes_demo'); }
};
