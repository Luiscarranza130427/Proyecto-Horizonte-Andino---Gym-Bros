<?php

namespace App\Services\Pagos;

use App\Models\OrdenCompra;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MercadoPagoService
{
    public function configurado(): void
    {
        foreach (['access_token','webhook_secret','notification_url','frontend_url','logo'] as $campo) {
            abort_unless(config('mercadopago.'.$campo),503);
        }
        foreach (['notification_url','frontend_url'] as $campo) {
            abort_unless(filter_var(config('mercadopago.'.$campo), FILTER_VALIDATE_URL)
                && parse_url(config('mercadopago.'.$campo), PHP_URL_SCHEME) === 'https',503);
        }
        abort_unless(parse_url(config('app.url'), PHP_URL_SCHEME) === 'https',503);
        abort_unless(is_file(public_path('storage/'.config('mercadopago.logo'))),503);
    }

    private function api(string $method, string $path, array $datos = [], ?string $key = null): array
    {
        abort_unless(config('mercadopago.access_token'),503);
        $http = Http::baseUrl('https://api.mercadopago.com')->withToken(config('mercadopago.access_token'))
            ->acceptJson()->connectTimeout(5)->timeout(15)->withoutRedirecting();
        if ($key) { $http = $http->withHeader('X-Idempotency-Key',$key); }
        $response = $method === 'GET' ? $http->get($path) : $http->post($path,$datos);
        // Never include provider responses or request headers in exceptions/logs.
        abort_unless($response->successful() && is_array($response->json()),502);
        return $response->json();
    }

    public function preferencia(OrdenCompra $orden): array
    {
        $front = rtrim(config('mercadopago.frontend_url'),'/').'/checkout/';
        return $this->api('POST','/checkout/preferences',[
            'items'=>[['id'=>(string) $orden->id_planes,'title'=>$orden->plan_nombre,'quantity'=>1,
                'currency_id'=>'PEN','unit_price'=>(float) $orden->monto]],
            'external_reference'=>$orden->uuid,
            'notification_url'=>config('mercadopago.notification_url'),
            'back_urls'=>['success'=>$front.'success','pending'=>$front.'pending','failure'=>$front.'failure'],
            'auto_return'=>'approved','expires'=>true,
            'expiration_date_to'=>$orden->expira_en->toIso8601String(),
        ],$orden->idempotency_key);
    }

    public function pago(string $id): array
    {
        abort_unless(preg_match('/^[0-9]+$/',$id),422);
        return $this->api('GET','/v1/payments/'.$id);
    }

    public function reembolsar(string $id, string $key): array
    {
        abort_unless(preg_match('/^[0-9]+$/',$id),422);
        return $this->api('POST','/v1/payments/'.$id.'/refunds',[], $key);
    }

    public function validarFirma(Request $request): string
    {
        abort_unless(config('mercadopago.webhook_secret'),503);
        // PHP normalizes data.id in query strings to data_id.
        $id = $request->query('data_id') ?? $request->query('data.id');
        $rid = $request->header('x-request-id','');
        $signature = $request->header('x-signature','');
        abort_unless(is_string($id) && preg_match('/^[0-9]+$/',$id) && preg_match('/^[a-zA-Z0-9-]{1,200}$/',$rid),401);
        abort_unless(preg_match('/^ts=([0-9]{10,13}),\s*v1=([a-fA-F0-9]{64})$/',$signature,$m),401);
        $ts = strlen($m[1]) === 13 ? intdiv((int) $m[1],1000) : (int) $m[1];
        abort_if(abs(now()->timestamp-$ts) > 300,401);
        $hash = hash_hmac('sha256','id:'.$id.';request-id:'.$rid.';ts:'.$m[1].';',config('mercadopago.webhook_secret'));
        abort_unless(hash_equals($hash,strtolower($m[2])),401);
        abort_unless($request->input('type') === 'payment' && (string) $request->input('data.id') === $id,422);
        return $id;
    }
}
