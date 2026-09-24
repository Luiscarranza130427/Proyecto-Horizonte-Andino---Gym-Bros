<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePlanAlimentacionRequest extends FormRequest
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
            'nombre' => ['nullable', 'string', 'max:150'],
            'descripcion' => ['nullable', 'string'],
            'objetivo' => ['nullable', 'string', 'max:100'],
            'calorias_objetivo' => ['nullable', 'numeric'],
            'proteinas_objetivo' => ['nullable', 'numeric'],
            'carbohidratos_objetivo' => ['nullable', 'numeric'],
            'grasas_objetivo' => ['nullable', 'numeric'],
            'fecha_inicio' => ['nullable', 'date'],
            'fecha_fin' => ['nullable', 'date'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
