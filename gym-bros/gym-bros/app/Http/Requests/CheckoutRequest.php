<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CheckoutRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    protected function prepareForValidation(): void
    {
        $datos = ['idempotency_key'=>$this->header('Idempotency-Key')];
        foreach (['usuario','empresa'] as $campo) {
            $valor = $this->input($campo);
            if (is_array($valor) && isset($valor['correo']) && is_string($valor['correo'])) {
                $valor['correo'] = mb_strtolower(trim($valor['correo']));
                $datos[$campo] = $valor;
            }
        }
        $this->merge($datos);
    }

    public function rules(): array
    {
        return [
            'idempotency_key'=>['required','uuid'], 'plan_id'=>['required','integer','min:1'],
            'usuario'=>['required','array:nombres,apellidos,apodo,genero,correo,tipo_documento,numero_documento,telefono,fecha_registro,fecha_nacimiento,tipo_usuario'],
            'usuario.apodo'=>['required','string','max:100'],
            'usuario.genero'=>['required','in:Varon,Mujer'],
            'usuario.tipo_documento'=>['required','in:DNI,PASAPORTE,OTRO'],
            'usuario.numero_documento'=>['required','string','max:12'],
            'usuario.fecha_registro'=>['required','date_format:Y-m-d','after_or_equal:1000-01-01','before_or_equal:today'],
            'usuario.fecha_nacimiento'=>['required','date_format:Y-m-d','after_or_equal:1000-01-01','before_or_equal:usuario.fecha_registro'],
            'usuario.tipo_usuario'=>['required','in:Empresa'],
            'usuario.nombres'=>['required','string','max:255'], 'usuario.apellidos'=>['required','string','max:255'],
            'usuario.correo'=>['required','email','not_regex:/[\x00-\x1F\x7F]/','max:255'], 'usuario.telefono'=>['required','regex:/^9[0-9]{8}$/'],
            'empresa'=>['required','array:nombre,nombre_gerente,correo,telefono'],
            'empresa.nombre'=>['required','string','max:150'], 'empresa.nombre_gerente'=>['required','string','max:200'],
            'empresa.correo'=>['required','email','not_regex:/[\x00-\x1F\x7F]/','max:150'], 'empresa.telefono'=>['required','regex:/^9[0-9]{8}$/'],
        ];
    }
}
