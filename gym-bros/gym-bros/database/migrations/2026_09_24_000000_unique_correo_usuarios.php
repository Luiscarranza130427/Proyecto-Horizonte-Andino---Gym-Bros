<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{DB,Schema};

return new class extends Migration {
    public function up(): void
    {
        if (DB::table('usuarios')->selectRaw('LOWER(TRIM(correo)) as correo_normalizado')
            ->groupByRaw('LOWER(TRIM(correo))')->havingRaw('COUNT(*) > 1')->exists()) {
            throw new RuntimeException('Existen correos duplicados. Resolverlos antes de habilitar la importacion.');
        }
        Schema::table('usuarios', fn (Blueprint $t) => $t->unique('correo', 'usuarios_correo_importacion_unique'));
    }

    public function down(): void
    {
        Schema::table('usuarios', fn (Blueprint $t) => $t->dropUnique('usuarios_correo_importacion_unique'));
    }
};
