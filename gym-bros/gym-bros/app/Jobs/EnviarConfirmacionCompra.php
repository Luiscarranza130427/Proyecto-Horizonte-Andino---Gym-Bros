<?php

namespace App\Jobs;

use App\Mail\ConfirmacionCompra;
use App\Models\OrdenCompra;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\{DB,Mail,URL};
use Illuminate\Support\Str;

class EnviarConfirmacionCompra implements ShouldQueue
{
    use Queueable;
    public int $tries = 5;
    public int $timeout = 60;
    public function __construct(public int $ordenId) {}
    public function backoff(): array { return [60,300,900,3600]; }
    public function handle(): void
    {
        try { $this->enviar(); }
        catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Confirmacion de compra pendiente.', ['orden_id'=>$this->ordenId,'exception'=>get_class($e)]);
            throw new \RuntimeException('No se pudo enviar la confirmacion de compra.');
        }
    }

    private function enviar(): void
    {
        if (in_array(config('mail.default'),['log','array','failover'],true) && !app()->environment('testing')) {
            throw new \RuntimeException('Configurar transporte real de correo para confirmar la compra.');
        }
        DB::transaction(function () {
            $orden = OrdenCompra::whereKey($this->ordenId)->lockForUpdate()->firstOrFail();
            if ($orden->estado !== 'aprobado' || $orden->correo_enviado_en) { return; }
            $url = rtrim(config('mercadopago.frontend_url'),'/');
            if (!$orden->password_establecida_en) {
                $token = Str::random(64);
                $expira = now()->addDays(2);
                $orden->update(['password_token_hash'=>hash('sha256',$token),'password_token_expira'=>$expira]);
                $api = URL::temporarySignedRoute('checkout.password',$expira,['orden_uuid'=>$orden->uuid,'token'=>$token]);
                $url .= '/establecer-contrasena?url='.rawurlencode($api);
            }
            Mail::to($orden->comprador['correo'])->send(new ConfirmacionCompra($orden,$url));
            $orden->update(['correo_enviado_en'=>now()]);
        });
    }
}
