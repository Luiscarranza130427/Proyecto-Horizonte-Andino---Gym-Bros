<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class EmpresaEjercicio extends Model
{
        use HasFactory;
    protected $table = 'empresa_ejercicio';
    protected $fillable = [
        'id_empresas',
        'id_ejercicios',
        'estado'
    ];

}
