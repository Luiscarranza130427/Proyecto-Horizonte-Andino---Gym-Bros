<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGrupoMuscularRequest extends FormRequest
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
            'descripcion' => ['nullable', 'string'],
            'estado' => ['nullable', 'boolean'],
            'tipo' => ['nullable', 'in:pecho,espalda,hombros,biceps,triceps,cuadriceps,isquiotibiales,gluteos,pantorrillas,abdomen']
        ];
    }
}
