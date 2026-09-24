<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreComidaAlimentoRequest extends FormRequest
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
            'id_comidas' => ['required', 'integer', 'exists:comidas,id'],
            'id_alimentos' => ['required', 'integer', 'exists:alimentos,id'],
            'cantidad' => ['required', 'numeric'],
            'unidad' => ['required', 'in:gramos,mililitros,unidad'],
            'notas' => ['nullable', 'string'],
        ];
    }
}
