<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Se lee de config (no de env) para que funcione con config:cache en produccion.
        if ($proxies = config('app.trusted_proxies')) {
            \Illuminate\Http\Middleware\TrustProxies::at(
                $proxies === '*' ? '*' : array_map('trim', explode(',', $proxies)));
        }

        \Illuminate\Support\Facades\Gate::define('gestionar-alimentacion', fn ($actor, \App\Models\Usuario $usuario) => $actor instanceof \App\Models\Usuario
            && \App\Support\Acceso::puedeSeguirUsuario($actor, $usuario));

        \Illuminate\Support\Facades\RateLimiter::for('recuperacion-password', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinutes(10, 5)->by($request->path().'|'.$request->ip())
                ->response(fn ($request, $headers) => response()->json([
                    'message'=>'Demasiados intentos. Intenta nuevamente mas tarde.',
                ],429,$headers));
        });
        \Illuminate\Support\Facades\RateLimiter::for('api-sesion', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(240)
                ->by('api|'.($request->user('sanctum')?->getKey() ?? $request->ip()))
                ->response(fn ($request, $headers) => response()->json([
                    'message' => 'Demasiadas solicitudes. Intenta nuevamente en un momento.',
                ], 429, $headers));
        });
        \Illuminate\Support\Facades\RateLimiter::for('login-sesion', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(5)->by($request->ip())
                ->response(fn ($request, $headers) => response()->json([
                    'message' => 'Demasiados intentos. Intenta nuevamente mas tarde.',
                ], 429, $headers));
        });
        \Illuminate\Support\Facades\RateLimiter::for('solicitudes-demo', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinutes(10, 5)->by($request->ip())
                ->response(fn ($request, $headers) => response()->json([
                    'message' => 'Has realizado demasiadas solicitudes. Intenta nuevamente más tarde.',
                ], 429, $headers));
        });
    }
}
