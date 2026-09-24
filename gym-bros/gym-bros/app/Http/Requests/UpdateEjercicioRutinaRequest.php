<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEjercicioRutinaRequest extends FormRequest
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
            'id_rutinas' => ['required', 'integer', 'exists:rutinas,id'],
            'id_ejercicios' => ['required', 'integer', 'exists:ejercicios,id'],
            'dia' => ['nullable', 'integer'],
            'orden' => ['nullable', 'integer'],
            'series' => ['nullable', 'integer'],
            'repeticiones' => ['nullable', 'integer'],
            'peso' => ['nullable', 'numeric'],
            'descanso_segundos' => ['nullable', 'integer'],
            'tiempo_segundos' => ['nullable', 'integer'],
            'notas' => ['nullable', 'string'],
        ];
    }
}
