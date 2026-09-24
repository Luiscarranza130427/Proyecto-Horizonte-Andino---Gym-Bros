<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePlanAlimentacionRequest extends FormRequest
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
            'id_usuario' => ['required', 'integer', 'exists:usuarios,id'],
            'nombre' => ['required', 'string', 'max:150'],
            'descripcion' => ['nullable', 'string'],
            'objetivo' => ['required', 'string', 'max:100'],
            'calorias_objetivo' => ['required', 'numeric'],
            'proteinas_objetivo' => ['required', 'numeric'],
            'carbohidratos_objetivo' => ['required', 'numeric'],
            'grasas_objetivo' => ['required', 'numeric'],
            'fecha_inicio' => ['required', 'date'],
            'fecha_fin' => ['required', 'date'],
            'activo' => ['required', 'boolean'],

        ];
    }
}
