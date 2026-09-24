<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('evaluaciones_fisicas', function (Blueprint $table) {
            // Historical units require explicit verification, not a guessed conversion.
            $table->enum('altura_unidad', ['cm'])->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('evaluaciones_fisicas', fn (Blueprint $table) => $table->dropColumn('altura_unidad'));
    }
};
