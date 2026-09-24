<?php

namespace App\Services\Pagos;

use App\Jobs\EnviarConfirmacionCompra;
use App\Models\{Empresa, OrdenCompra, Pago, Plan, Suscripcion, Usuario};
use Brick\Math\BigDecimal;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\{DB, Hash, Log};
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class CheckoutService
{
    public function __construct(private MercadoPagoService $mp) {}

    public static function centavos(mixed $monto): int
    {
        try { return BigDecimal::of((string) $monto)->multipliedBy(100)->toInt(); }
        catch (\Throwable) { abort(422); }
    }

    public function crear(array $datos): OrdenCompra
    {
        $this->mp->configurado();
        $hash = hash('sha256',json_encode([$datos['plan_id'],$datos['usuario'],$datos['empresa']],JSON_THROW_ON_ERROR));
        $orden = DB::transaction(function () use ($datos,$hash) {
            $orden = OrdenCompra::where('idempotency_key',$datos['idempotency_key'])->lockForUpdate()->first();
            if ($orden) { abort_unless(hash_equals($orden->request_hash,$hash),409); return $orden; }
            $plan = Plan::whereKey($datos['plan_id'])->lockForUpdate()->first();
            if (! $plan || ! $plan->activo || $plan->duracion_dias < 1 || $plan->duracion_dias > 36500
                || self::centavos($plan->precio_inicial) < 1 || self::centavos($plan->precio_inicial) > 9999999999) {
                throw ValidationException::withMessages(['plan_id'=>'Seleccione un plan activo con precio y duracion validos.']);
            }
            if (Usuario::whereRaw('LOWER(TRIM(correo)) = ?',[$datos['usuario']['correo']])->exists()) {
                throw ValidationException::withMessages(['checkout'=>'No se puede iniciar esta compra. Acceda a su cuenta o contacte con soporte.']);
            }
            return OrdenCompra::create([
                'uuid'=>(string) Str::uuid(),'id_planes'=>$plan->id,'plan_nombre'=>$plan->nombre,
                'monto'=>$plan->precio_inicial,'moneda'=>'PEN','duracion_dias'=>$plan->duracion_dias,
                'comprador'=>$datos['usuario'],'empresa_datos'=>$datos['empresa'],'estado'=>'pendiente',
                'idempotency_key'=>$datos['idempotency_key'],'request_hash'=>$hash,'expira_en'=>now()->addDay(),
            ]);
        });
        return DB::transaction(function () use ($orden) {
            $orden = OrdenCompra::whereKey($orden->id)->lockForUpdate()->firstOrFail();
            abort_if($orden->expira_en->isPast(),409);
            if ($orden->preference_id) { return $orden; }
            abort_unless($orden->estado === 'pendiente',409);
            $respuesta = $this->mp->preferencia($orden);
            $url = $respuesta['init_point'] ?? null;
            abort_unless(is_string($url) && parse_url($url,PHP_URL_SCHEME) === 'https'
                && preg_match('/(^|\.)mercadopago\.(com|com\.pe)$/',(string) parse_url($url,PHP_URL_HOST))
                && is_string($respuesta['id'] ?? null),502);
            $orden->update(['preference_id'=>$respuesta['id'],'checkout_url'=>$url,'estado'=>'checkout_creado']);
            return $orden;
        });
    }

    public function procesar(string $paymentId): void
    {
        $pago = $this->mp->pago($paymentId);
        abort_unless((string) ($pago['id'] ?? '') === $paymentId,422);
        $id = OrdenCompra::where('uuid',$pago['external_reference'] ?? '')->value('id');
        abort_unless($id,422);
        DB::transaction(function () use ($id,$paymentId) {
            $orden = OrdenCompra::whereKey($id)->lockForUpdate()->firstOrFail();
            // Re-read under the order lock so concurrent/out-of-order events cannot regress state.
            $pago = $this->mp->pago($paymentId);
            $this->verificar($orden,$pago,$paymentId);
            if ($orden->payment_id && $orden->payment_id !== $paymentId) { abort(409); }
            if (($pago['status'] ?? '') === 'refunded' && $orden->id_pagos) {
                abort_unless(self::centavos($pago['transaction_amount_refunded'] ?? 0) === self::centavos($orden->monto),422);
                $this->confirmarReembolso($orden);
                return;
            }
            if (in_array($orden->estado,['aprobado','reembolsado'],true)) { return; }
            if (($pago['status'] ?? '') !== 'approved') {
                $estado = match ($pago['status'] ?? '') {
                    'rejected'=>'rechazado','cancelled'=>'cancelado',default=>'procesando',
                };
                $orden->update(['estado'=>$estado]);
                return;
            }
            abort_unless(!empty($pago['date_approved']),422);
            $aprobado = CarbonImmutable::parse($pago['date_approved'])->utc();
            abort_if($aprobado->isAfter($orden->expira_en) || $aprobado->isAfter(now()->addMinutes(5)),409);
            $comprador = $orden->comprador;
            abort_if(Usuario::whereRaw('LOWER(TRIM(correo)) = ?',[$comprador['correo']])->exists(),409);
            $inicio = $aprobado->setTimezone('America/Lima')->startOfDay();
            $fin = $inicio->addDays($orden->duracion_dias);
            $empresa = Empresa::create(array_merge($orden->empresa_datos,[
                'estado'=>true,'fecha_registro'=>$inicio->toDateString(),'logo'=>config('mercadopago.logo'),
                'color_1'=>config('mercadopago.color_1'),'color_2'=>config('mercadopago.color_2'),
            ]));
            $usuario = Usuario::create(array_merge($comprador,[
                'tipo_usuario'=>'Empresa','estado'=>true,'id_empresas'=>$empresa->id,
                'fecha_registro'=>$comprador['fecha_registro'] ?? $inicio->toDateString(),'password_hash'=>Hash::make(Str::random(80)),
                'inicio_suscripcion'=>null,'fin_suscripcion'=>null,
            ]));
            $suscripcion = Suscripcion::create(['id_empresas'=>$empresa->id,'id_planes'=>$orden->id_planes,
                'fecha_inicio'=>$inicio->toDateString(),'fecha_fin'=>$fin->toDateString(),'estado'=>'activa','renovacion_automatica'=>false]);
            $registro = new Pago(['id_empresas'=>$empresa->id,'id_suscripciones'=>$suscripcion->id,
                'monto'=>$orden->monto,'moneda'=>'PEN','metodo_pago'=>substr((string) ($pago['payment_type_id'] ?? 'mercadopago'),0,50),
                'referencia'=>$orden->uuid,'estado'=>'aprobado','fecha_pago'=>$aprobado->toDateTimeString()]);
            $registro->forceFill(['proveedor'=>'mercadopago','proveedor_payment_id'=>$paymentId,
                'preference_id'=>$orden->preference_id,'external_reference'=>$orden->uuid,
                'idempotency_key'=>$orden->idempotency_key,'estado_detalle'=>substr((string) ($pago['status_detail'] ?? ''),0,255),
                'aprobado_en'=>$aprobado->toDateTimeString()])->saveOrFail();
            $orden->update(['estado'=>'aprobado','payment_id'=>$paymentId,'aprobado_en'=>$aprobado,
                'id_empresas'=>$empresa->id,'id_usuarios'=>$usuario->id,'id_suscripciones'=>$suscripcion->id,'id_pagos'=>$registro->id]);
        });
        // A queue outage must not roll back a verified payment. The scheduled outbox retries.
        $orden = OrdenCompra::findOrFail($id);
        if ($orden->estado === 'aprobado' && ! $orden->correo_enviado_en) {
            try { EnviarConfirmacionCompra::dispatch($orden->id)->onConnection('database'); }
            catch (\Throwable) { Log::error('Compra aprobada: confirmacion pendiente de encolar.',['orden'=>$orden->uuid]); }
        }
    }

    public function verificar(OrdenCompra $orden, array $pago, string $id): void
    {
        abort_unless((string) ($pago['id'] ?? '') === $id && ($pago['external_reference'] ?? '') === $orden->uuid
            && ($pago['currency_id'] ?? '') === 'PEN'
            && self::centavos($pago['transaction_amount'] ?? -1) === self::centavos($orden->monto)
            && isset($pago['live_mode']) && $pago['live_mode'] === (bool) config('mercadopago.live_mode'),422);
    }

    public function confirmarReembolso(OrdenCompra $orden): void
    {
        Pago::whereKey($orden->id_pagos)->update(['estado'=>'reembolsado','reembolsado_en'=>now(), 'monto_reembolsado'=>$orden->monto]);
        Suscripcion::whereKey($orden->id_suscripciones)->update(['estado'=>'cancelada']);
        $orden->update(['estado'=>'reembolsado']);
        DB::table('reembolsos_pago')->where('id_pago',$orden->id_pagos)->update(['estado'=>'aprobado','updated_at'=>now()]);
    }
}
