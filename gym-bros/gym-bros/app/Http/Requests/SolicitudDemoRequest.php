<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class SolicitudDemoRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return ['correo' => ['required', 'string', 'email', 'max:150', 'not_regex:/[\x00-\x1F\x7F]/']];
    }

    public function messages(): array
    {
        return ['correo.required' => 'El correo es obligatorio.',
            'correo.email' => 'Ingresa un correo electrónico válido.',
            'correo.max' => 'El correo no debe superar 150 caracteres.',
            'correo.string' => 'Ingresa un correo electrónico válido.',
            'correo.not_regex' => 'Ingresa un correo electrónico válido.'];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos proporcionados no son válidos.',
            'errors' => $validator->errors(),
        ], 422));
    }
}
