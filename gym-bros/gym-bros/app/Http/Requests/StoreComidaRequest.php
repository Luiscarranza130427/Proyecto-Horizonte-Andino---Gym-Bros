<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreComidaRequest extends FormRequest
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
            'id_planes_alimentacion' => ['required', 'integer', 'exists:planes_alimentacion,id'],
            'nombre' => ['required', 'string', 'max:100'],
            'tipo_comida' => ['required', 'in:desayuno,media_manana,almuerzo,media_tarde,cena,snack,otro'],
            'orden' => ['required', 'integer'],
            'hora_sugerida' => ['nullable', 'date_format:H:i'],
            'notas' => ['nullable', 'string'],
        ];
    }
}
