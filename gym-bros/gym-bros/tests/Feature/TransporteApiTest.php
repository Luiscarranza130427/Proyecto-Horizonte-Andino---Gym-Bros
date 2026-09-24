<?php

namespace Tests\Feature;

use Tests\TestCase;

class TransporteApiTest extends TestCase
{
    public function test_ruta_desconocida_devuelve_json_incluso_sin_accept(): void
    {
        $this->get('/api/no-existe')->assertNotFound()->assertHeader('Content-Type', 'application/json');
    }

    public function test_preflight_admite_panel_y_flutter_con_bearer(): void
    {
        config(['cors.allowed_origins' => ['http://localhost:5173', 'http://127.0.0.1:8080']]);
        foreach (['http://localhost:5173', 'http://127.0.0.1:8080'] as $origen) {
            $this->options('/api/auth/login', [], ['Origin' => $origen,
                'Access-Control-Request-Method' => 'POST',
                'Access-Control-Request-Headers' => 'authorization,content-type'])
                ->assertNoContent()->assertHeader('Access-Control-Allow-Origin', $origen);
        }
    }
}
