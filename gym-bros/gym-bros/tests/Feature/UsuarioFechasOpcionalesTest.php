<?php

namespace Tests\Feature;

use App\Http\Requests\StoreUsuarioRequest;
use App\Http\Requests\UpdateUsuarioRequest;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class UsuarioFechasOpcionalesTest extends TestCase
{
    public function test_fechas_omitidas_nulas_o_independientes_son_validas(): void
    {
        foreach ([StoreUsuarioRequest::class, UpdateUsuarioRequest::class] as $class) {
            foreach ([[], ['inicio_suscripcion' => null, 'fin_suscripcion' => null],
                ['inicio_suscripcion' => '2026-09-01'], ['fin_suscripcion' => '2026-09-30'],
                ['inicio_suscripcion' => null, 'fin_suscripcion' => '2026-09-30']] as $data) {
                $request = $class::create('/', 'POST', $data);
                $rules = array_intersect_key($request->rules(), array_flip(['inicio_suscripcion', 'fin_suscripcion']));
                $this->assertTrue(Validator::make($data, $rules)->passes());
            }
        }
    }

    public function test_edicion_rechaza_fechas_invalidas_y_orden_invertido(): void
    {
        foreach ([['inicio_suscripcion' => 'incorrecto'], ['fin_suscripcion' => '2026-02-30'],
            ['inicio_suscripcion' => '2026-09-30', 'fin_suscripcion' => '2026-09-01']] as $data) {
            $request = UpdateUsuarioRequest::create('/', 'PUT', $data);
            $rules = array_intersect_key($request->rules(), array_flip(['inicio_suscripcion', 'fin_suscripcion']));
            $this->assertTrue(Validator::make($data, $rules)->fails());
        }
    }
}
