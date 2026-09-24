<?php

namespace App\Models;
use App\Models\Usuario;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Notificacion extends Model
{
    use HasFactory;
    protected $table = 'notificaciones';
    protected $fillable = [
        'id_empresas',
        'id_usuarios',
        'tipo',
        'titulo',
        'mensaje',
        'fecha_envio',
        'leida',
        'enviada',
        'datos'
    ];

    protected $casts = ['datos' => 'array', 'leida' => 'boolean', 'enviada' => 'boolean'];

    public function empresa()
    {
        return $this->belongsTo(Empresa::class,'id_empresas');
    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class,'id_usuarios');
    }
}
