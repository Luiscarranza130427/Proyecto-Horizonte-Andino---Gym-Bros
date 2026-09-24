<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSensacionRequest extends FormRequest
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
            'id_rutinas' => ['required', 'integer', 'exists:rutinas,id'],
            'fecha' => ['required', 'date'],
            'energia' => ['required', 'integer'],
            'dificultad' => ['required', 'integer'],
            'fatiga' => ['required', 'integer'],
            'dolor' => ['required', 'integer'],
            'comentario' => ['required', 'string'],
        ];
    }
}
