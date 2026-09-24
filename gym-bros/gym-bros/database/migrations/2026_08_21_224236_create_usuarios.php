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
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('nombres', 255);
            $table->string('apellidos', 255);
            $table->string('apodo',100);
            $table->enum('genero',['Varon','Mujer']);
            $table->string('correo', 255);
            $table->string('password_hash', 255);
            $table->enum('tipo_documento',['DNI','PASAPORTE','OTRO']);
            $table->string('numero_documento', 12);
            $table->string('telefono', 12);
            $table->string('direccion', 255)->nullable();
            $table->string('foto_perfil', 255)->nullable();
            $table->date('fecha_registro');
            $table->date('fecha_nacimiento');
            $table->date('inicio_suscripcion')->nullable();
            $table->date('fin_suscripcion')->nullable();
            $table->dateTime('asistencia_semanal')->nullable();
            $table->enum('tipo_usuario',['Adm0inistrador','Empresa','Entrenador','Usuario']);
            $table->boolean('estado')->default(true);
            $table->foreignId('id_empresas')->constrained('empresas')->onDelete('cascade');
            $table->timestamps();

        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('usuarios');
    }
};
