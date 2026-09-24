<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
public function up(): void
{
    Schema::table('evaluaciones_fisicas', function (Blueprint $table) {

        $table->foreignId('id_usuarios')
            ->constrained('usuarios')
            ->onDelete('cascade');

    });
}

    public function down(): void
    {
        Schema::table('evaluaciones_fisicas', function (Blueprint $table) {

            $table->dropForeign(['id_usuarios']);

            $table->dropColumn('id_usuarios');
        });
    }
};
