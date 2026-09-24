<?php

namespace App\Services\Pagos;

use App\Models\{OrdenCompra,Pago,Usuario};
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\{DB,Gate};
use Illuminate\Support\Str;

class RefundService
{
    public function solicitar(Usuario $usuario, Pago $pago, string $motivo): void
    {
        abort_unless(Gate::forUser($usuario)->allows('reembolsar',$pago),403);
        $id = OrdenCompra::where('id_pagos',$pago->id)->value('id');
        abort_unless($id,409);
        DB::transaction(function () use ($id,$usuario,$pago,$motivo) {
            $orden = OrdenCompra::whereKey($id)->lockForUpdate()->firstOrFail();
            $pago = Pago::whereKey($pago->id)->lockForUpdate()->firstOrFail();
            abort_unless(Gate::forUser($usuario)->allows('reembolsar',$pago),403);
            abort_unless($orden->estado === 'aprobado' && $pago->estado === 'aprobado' && $pago->aprobado_en,409);
            $limite = CarbonImmutable::parse($pago->aprobado_en,'UTC')->setTimezone('America/Lima')->addDays(5)->endOfDay();
            abort_if(CarbonImmutable::now('America/Lima')->isAfter($limite),422);
            if (! DB::table('reembolsos_pago')->where('id_pago',$pago->id)->exists()) {
                DB::table('reembolsos_pago')->insert(['id_pago'=>$pago->id,'id_usuario'=>$usuario->id,
                    'motivo'=>$motivo,'idempotency_key'=>(string) Str::uuid(),'estado'=>'pendiente','created_at'=>now(),'updated_at'=>now()]);
            }
        });
        DB::transaction(function () use ($id) {
            $orden = OrdenCompra::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_unless($orden->estado === 'aprobado',409);
            $intento = DB::table('reembolsos_pago')->where('id_pago',$orden->id_pagos)->lockForUpdate()->first();
            $mp = app(MercadoPagoService::class);
            $service = app(CheckoutService::class);
            $actual = $mp->pago($orden->payment_id);
            $service->verificar($orden,$actual,$orden->payment_id);
            if (($actual['status'] ?? '') !== 'refunded') {
                abort_unless(($actual['status'] ?? '') === 'approved',409);
                $respuesta = $mp->reembolsar($orden->payment_id,$intento->idempotency_key);
                abort_unless(($respuesta['status'] ?? '') === 'approved'
                    && (string) ($respuesta['payment_id'] ?? '') === $orden->payment_id
                    && CheckoutService::centavos($respuesta['amount'] ?? -1) === CheckoutService::centavos($orden->monto),422);
                DB::table('reembolsos_pago')->where('id',$intento->id)->update(['proveedor_refund_id'=>(string) $respuesta['id']]);
                $actual = $mp->pago($orden->payment_id);
                $service->verificar($orden,$actual,$orden->payment_id);
            }
            abort_unless(($actual['status'] ?? '') === 'refunded'
                && CheckoutService::centavos($actual['transaction_amount_refunded'] ?? 0) === CheckoutService::centavos($orden->monto),422);
            $service->confirmarReembolso($orden);
        });
    }
}
