<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

class CheckoutJson
{
    public function handle(Request $request, Closure $next)
    {
        $request->headers->set('Accept','application/json');
        try {
            abort_unless(config('mercadopago.enabled'),503,'Checkout pendiente de configuracion.');
            if (app()->environment('production')) {
                abort_unless($request->isSecure(),400,'Se requiere HTTPS.');
            }
            $origin = $request->header('Origin');
            abort_if($origin && rtrim($origin,'/') !== rtrim((string) config('mercadopago.frontend_url'),'/'),403);
            return $next($request);
        } catch (ValidationException $e) {
            return response()->json(['message'=>'Datos no validos.','errors'=>$e->errors()],422);
        } catch (\Illuminate\Auth\AuthenticationException $e) {
            return response()->json(['message'=>'Se requiere autenticacion.'],401);
        } catch (\Throwable $e) {
            $status = match (true) {
                $e instanceof HttpExceptionInterface => $e->getStatusCode(),
                $e instanceof \Illuminate\Auth\Access\AuthorizationException => 403,
                $e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException => 404,
                default => 500,
            };
            if ($status >= 500) {
                Log::error('Checkout: operacion no completada.', ['exception'=>get_class($e)]);
            }
            return response()->json(['message'=>match ($status) {
                401=>'Credenciales o firma no validas.',403=>'Operacion no autorizada.',404=>'Recurso no encontrado.',
                409=>'La operacion no puede completarse en su estado actual.',422=>'No se pudo verificar la operacion.',
                429=>'Demasiadas solicitudes.',503=>'Checkout pendiente de configuracion o temporalmente no disponible.',
                default=>'No se pudo completar la operacion.',
            }], $status);
        }
    }
}
