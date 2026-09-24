<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('alimentos', 'activo')) {
            Schema::table('alimentos', function (Blueprint $table) {
                $table->boolean('activo')->default(true);
            });
        }
        // Medical history is not converted into preferences. Back up before running.
        Schema::dropIfExists('usuario_restriccion_alimentaria');
        Schema::dropIfExists('alimento_restriccion');
        Schema::dropIfExists('restricciones_alimentarias');
    }

    public function down(): void
    {
        throw new RuntimeException('Esta migracion elimina antecedentes. Para recuperarlos se requiere el respaldo previo, no recrear tablas vacias.');
    }
};
