<?php

namespace Tests\Feature;

use App\Providers\AppServiceProvider;
use Illuminate\Http\Middleware\TrustProxies;
use Tests\TestCase;

/**
 * En produccion la API va detras de un proxy que termina TLS. Sin proxies de
 * confianza Laravel ve HTTP y ApiSesion rechazaba todo con 400.
 */
class ProxyConfianzaTest extends TestCase
{
    protected function tearDown(): void
    {
        TrustProxies::flushState();
        parent::tearDown();
    }

    public function test_detras_de_un_proxy_de_confianza_la_peticion_se_considera_https(): void
    {
        $this->app->instance('env', 'production');
        $cabeceras = ['X-Forwarded-Proto' => 'https', 'X-Forwarded-For' => '203.0.113.7', 'Accept' => 'application/json'];

        // Sin proxies de confianza, la cabecera se ignora: la API exige HTTPS.
        $this->withHeaders($cabeceras)->get('http://api.test/api/auth/me')->assertStatus(400);

        config(['app.trusted_proxies' => '*']);
        (new AppServiceProvider($this->app))->boot();

        // Con el proxy de confianza ya pasa el control de HTTPS y llega al de sesion.
        $this->withHeaders($cabeceras)->get('http://api.test/api/auth/me')->assertUnauthorized();
    }
}
