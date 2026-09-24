<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProgresoRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'id_usuarios' => ['required', 'integer', 'exists:usuarios,id'],
            'fecha' => ['required', 'date'],
            'peso' => ['nullable', 'numeric'],
            'altura' => ['nullable', 'numeric'],
            'porcentaje_grasa' => ['nullable', 'numeric'],
            'masa_muscular' => ['nullable', 'numeric'],
            'cintura' => ['nullable', 'numeric'],
            'pecho' => ['nullable', 'numeric'],
            'brazo' => ['nullable', 'numeric'],
            'muslo' => ['nullable', 'numeric'],
            'cadera' => ['nullable', 'numeric'],
            'notas' => ['nullable', 'string'],
        ];
    }
}
