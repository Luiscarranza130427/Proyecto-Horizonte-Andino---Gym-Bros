<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRutinaRequest extends FormRequest
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
            'nombre' => ['nullable', 'string', 'max:100'],
            'descripcion' => ['nullable', 'string'],
            'objetivo' => ['nullable', 'string', 'max:100'],
            'dias_semana' => ['nullable', 'integer'],
            'duracion_estimada' => ['nullable', 'integer'],
            'fecha_inicio' => ['nullable', 'date'],
            'fecha_fin' => ['nullable', 'date'],
            'estado' => ['nullable', 'boolean'],
        ];
    }
}
