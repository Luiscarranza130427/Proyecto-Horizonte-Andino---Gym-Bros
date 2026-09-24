<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('perfiles_alimentarios', function (Blueprint $table) {
            $table->string('revision_profesional', 200)->nullable()->change();
            $table->date('revisado_en')->nullable()->change();
        });
    }

    public function down(): void
    {
        if (DB::table('perfiles_alimentarios')->whereNull('revision_profesional')->orWhereNull('revisado_en')->exists()) {
            throw new RuntimeException('No se puede restaurar NOT NULL mientras existan revisiones ausentes. No se inventaran valores.');
        }
        Schema::table('perfiles_alimentarios', function (Blueprint $table) {
            $table->string('revision_profesional', 200)->nullable(false)->change();
            $table->date('revisado_en')->nullable(false)->change();
        });
    }
};
