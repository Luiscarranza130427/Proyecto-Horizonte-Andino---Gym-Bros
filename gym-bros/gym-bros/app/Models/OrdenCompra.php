<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrdenCompra extends Model
{
    protected $table = 'ordenes_compra';
    protected $guarded = ['id'];
    protected $hidden = ['comprador','empresa_datos','request_hash','idempotency_key','password_token_hash'];
    protected $casts = ['comprador'=>'encrypted:array','empresa_datos'=>'encrypted:array','monto'=>'decimal:2',
        'expira_en'=>'immutable_datetime','aprobado_en'=>'immutable_datetime','password_token_expira'=>'immutable_datetime'];
}
