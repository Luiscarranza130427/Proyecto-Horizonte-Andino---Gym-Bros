<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreEjercicioRequest extends FormRequest
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
            'nombre' => ['required', 'string', 'max:100'],
            'descripcion' => ['nullable', 'string'],
            'tipo' => ['required', 'in:fuerza,cardio,flexibilidad,equilibrio'],
            'instrucciones' => ['required', 'string'],
            'nivel' => ['required', 'in:principiante,intermedio,avanzado'],
            'equipamiento' => ['required', 'string', 'max:100'],
            'estado' => ['sometimes', 'required', 'boolean'],
            'enlace_video' => ['nullable', 'string', 'max:350'],
            'imagen_ejercicio' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'id_grupos_musculares' => ['required', 'integer', 'exists:grupos_musculares,id'],

        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['nivel', 'tipo'] as $campo) {
            if (is_string($this->input($campo))) {
                $this->merge([$campo => mb_strtolower(trim($this->input($campo)))]);
            }
        }
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos del ejercicio no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
