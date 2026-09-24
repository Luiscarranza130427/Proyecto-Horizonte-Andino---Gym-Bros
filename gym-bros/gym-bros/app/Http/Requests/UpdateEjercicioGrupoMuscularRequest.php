<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEjercicioGrupoMuscularRequest extends FormRequest
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
            'id_ejercicios' => ['required', 'integer', 'exists:ejercicios,id'],
            'id_grupos_musculares' => ['required', 'integer', 'exists:grupos_musculares,id'],
        ];
    }
}
