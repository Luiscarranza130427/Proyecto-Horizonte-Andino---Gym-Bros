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
        Schema::create('empresas', function (Blueprint $table) {
            $table->id();
            $table->string('nombre',150);
            $table->string('nombre_gerente',200);
            $table->enum('region', ['Amazonas','Ancash','Apurimac','Arequipa','Ayacucho','Cajamarca','Callao','Cusco','Huancavelica','Huanuco',
                        'Ica','Junin','La Libertad','Lambayeque','Lima','Loreto','Madre de Dios','Moquegua','Pasco','Piura','Puno',
                        'San Martin','Tacna','Tumbes','Ucayali'])->nullable();
            $table->string('ruc',12)->nullable();
            $table->string('enlace_web',300)->nullable();
            $table->string('direccion',250)->nullable();
            $table->string('telefono',9);
            $table->string('correo',150);
            $table->boolean('estado')->default(true);
            $table->date('fecha_registro');
            $table->string('logo',300);
            $table->string('color_1',10);
            $table->string('color_2',10);
            $table->string('banner_1',300)->nullable();
            $table->string('banner_2',300)->nullable();
            $table->string('banner_3',300)->nullable();
            $table->string('link_boton_1',200)->nullable();
            $table->string('link_boton_2',200)->nullable();
            $table->string('link_boton_3',200)->nullable();
            $table->decimal('horario_inicio_lunes',4,2)->nullable();
            $table->decimal('horario_fin_lunes',4,2)->nullable();
            $table->decimal('horario_inicio_martes',4,2)->nullable();
            $table->decimal('horario_fin_martes',4,2)->nullable();
            $table->decimal('horario_inicio_miercoles',4,2)->nullable();
            $table->decimal('horario_fin_miercoles',4,2)->nullable();
            $table->decimal('horario_inicio_jueves',4,2)->nullable();
            $table->decimal('horario_fin_jueves',4,2)->nullable();
            $table->decimal('horario_inicio_viernes',4,2)->nullable();
            $table->decimal('horario_fin_viernes',4,2)->nullable();
            $table->decimal('horario_inicio_sabado',4,2)->nullable();
            $table->decimal('horario_fin_sabado',4,2)->nullable();
            $table->decimal('horario_inicio_domingo',4,2)->nullable();
            $table->decimal('horario_fin_domingo',4,2)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('empresas');
    }
};
