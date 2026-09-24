<?php

namespace Tests\Feature;

use App\Http\Controllers\EmpresaController;
use App\Http\Resources\EmpresaResource;
use App\Models\Empresa;
use Illuminate\Http\Request;
use Illuminate\Routing\Route;
use Tests\TestCase;

class EmpresaResourceTest extends TestCase
{
    public function test_index_includes_registration_date_without_changing_model(): void
    {
        $empresa = new Empresa(['nombre' => 'Empresa de prueba', 'fecha_registro' => '2026-09-09']);
        $resource = new EmpresaResource($empresa);
        $original = $resource->resolve(Request::create('/'));
        $expected = $original;

        $request = Request::create('/api/empresas');
        $route = app('router')->getRoutes()->match($request);
        $request->setRouteResolver(fn () => $route);

        $this->assertSame($expected, $resource->resolve($request));
        $this->assertSame('2026-09-09', $resource->resolve($request)['fecha_registro']);
        $this->assertSame('2026-09-09', $empresa->fecha_registro);
        $this->assertSame($original, $resource->resolve(Request::create('/')));
    }

    public function test_other_company_responses_keep_registration_date(): void
    {
        foreach (['show', 'store'] as $method) {
            $request = Request::create('/api/empresas/1');
            $action = EmpresaController::class.'@'.$method;
            $route = new Route('GET', 'api/empresas/1', ['uses' => $action, 'controller' => $action]);
            $request->setRouteResolver(fn () => $route);
            $data = (new EmpresaResource(new Empresa(['fecha_registro' => '2026-09-09'])))->resolve($request);
            $this->assertSame('2026-09-09', $data['fecha_registro']);
        }
    }
}
