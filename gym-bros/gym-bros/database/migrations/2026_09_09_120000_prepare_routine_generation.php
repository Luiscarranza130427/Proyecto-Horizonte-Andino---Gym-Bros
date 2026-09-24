<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ejercicios_grupo_muscular', function (Blueprint $table) {
            $table->foreignId('id_grupos_musculares')->nullable()->constrained('grupos_musculares')->onDelete('cascade');
        });

        // Preserve all existing rows and infer only the already recorded primary muscle.
        DB::table('ejercicios_grupo_muscular')->orderBy('id')->chunkById(200, function ($rows) {
            foreach ($rows as $row) {
                DB::table('ejercicios_grupo_muscular')->where('id', $row->id)->update([
                    'id_grupos_musculares' => DB::table('ejercicios')->where('id', $row->id_ejercicios)->value('id_grupos_musculares'),
                ]);
            }
        });

        Schema::table('evaluaciones_fisicas', function (Blueprint $table) {
            $table->text('eleccion_dias')->nullable()->change();
            $table->enum('nivel_experiencia', ['1a3meses', '4a8anos', '4a8meses', '1ano', 'mas1ano', '2anos', '3anosamas', '3anos_mas'])->change();
        });
    }

    public function down(): void
    {
        // Refuse a lossy rollback when newer values cannot fit the original enums.
        $dias = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
        $incompatible = DB::table('evaluaciones_fisicas')->where(function ($query) use ($dias) {
            $query->whereNull('eleccion_dias')->orWhereNotIn('eleccion_dias', $dias)
                ->orWhereIn('nivel_experiencia', ['4a8meses', '3anos_mas']);
        })->exists();
        if ($incompatible) {
            throw new RuntimeException('Rollback cancelado: hay evaluaciones incompatibles con los enums anteriores.');
        }
        $secundarios = DB::table('ejercicios_grupo_muscular as relacion')->join('ejercicios', 'ejercicios.id', '=', 'relacion.id_ejercicios')
            ->whereColumn('relacion.id_grupos_musculares', '<>', 'ejercicios.id_grupos_musculares')->exists();
        if ($secundarios) {
            throw new RuntimeException('Rollback cancelado: se perderian relaciones de musculos secundarios.');
        }

        Schema::table('evaluaciones_fisicas', function (Blueprint $table) use ($dias) {
            $table->enum('eleccion_dias', $dias)->nullable(false)->change();
            $table->enum('nivel_experiencia', ['1a3meses', '4a8anos', '1ano', 'mas1ano', '2anos', '3anosamas'])->change();
        });
        Schema::table('ejercicios_grupo_muscular', function (Blueprint $table) {
            $table->dropForeign(['id_grupos_musculares']);
            $table->dropColumn('id_grupos_musculares');
        });
    }
};
