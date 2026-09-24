<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class UpdateUsuarioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nombres' => ['sometimes', 'required', 'string', 'max:255'],
            'apellidos' => ['sometimes', 'required', 'string', 'max:255'],
            'apodo' => ['sometimes', 'required', 'string', 'max:100'],
            'correo' => ['sometimes', 'required', 'email', 'max:255', 'not_regex:/[\x00-\x1F\x7F]/',
                Rule::unique('usuarios', 'correo')->ignore($this->route('id_usuario'), 'id')],
            'telefono' => ['sometimes', 'required', 'string', 'max:12'],
            'tipo_documento' => ['sometimes', 'required', Rule::in(['DNI', 'PASAPORTE', 'OTRO'])],
            'numero_documento' => ['sometimes', 'required', 'string', 'max:12'],
            'genero' => ['sometimes', 'required', Rule::in(['Varon', 'Mujer'])],
            'fecha_nacimiento' => ['sometimes', 'required', 'date_format:Y-m-d', 'after_or_equal:1000-01-01', 'before_or_equal:today'],
            'inicio_suscripcion' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'fin_suscripcion'=> ['sometimes', 'nullable', 'date_format:Y-m-d', Rule::when($this->filled('inicio_suscripcion'), ['after_or_equal:inicio_suscripcion'])],
            'direccion' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable del usuario.');
            }
        }];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos del usuario no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
