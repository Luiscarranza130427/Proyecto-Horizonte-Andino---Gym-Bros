<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Usuario extends Authenticatable
{
    use HasFactory;
    use HasApiTokens;

    public function getAuthPasswordName()
    {
        return 'password_hash';
    }

    public function getEmailForPasswordReset()
    {
        return mb_strtolower(trim($this->correo));
    }

    public function getRememberTokenName()
    {
        return '';
    }
    protected $table = 'usuarios';
    protected $fillable = [
        'nombres',
        'apellidos',
        'apodo',
        'genero',
        'correo',
        'password_hash',
        'tipo_documento',
        'numero_documento',
        'telefono',
        'direccion',
        'foto_perfil',
        'fecha_registro',
        'fecha_nacimiento',
        'asistencia_semanal',
        'inicio_suscripcion',
        'fin_suscripcion',
        'tipo_usuario',
        'estado',
        'id_empresas'
    ];

    protected $hidden =[
        'password_hash',
        'correo_normalizado',
    ];

    public function empresa()
    {
        return $this->belongsTo(Empresa::class,'id_empresas');
    }

    public function evaluacionesFisicas()
    {
        return $this->hasMany(EvaluacionFisica::class, 'id_usuarios');
    }

    public function rutinas()
    {
        return $this->hasMany(Rutina::class, 'id_usuarios');
    }
}
