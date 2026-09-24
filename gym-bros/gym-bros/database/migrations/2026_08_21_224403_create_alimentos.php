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
        Schema::create('alimentos', function (Blueprint $table) {
            $table->id();
            $table->string('nombre',150);
            $table->enum('tipo',['proteina','carbohidrato','grasa','fruta','verdura','lacteo','cereal','legumbre','bebida','otro']);
            $table->decimal('calorias',6,2);
            $table->decimal('proteinas',6,2);
            $table->decimal('carbohidratos',6,2);
            $table->decimal('grasas',6,2);
            $table->decimal('fibra',6,2);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('alimentos');
    }
};
