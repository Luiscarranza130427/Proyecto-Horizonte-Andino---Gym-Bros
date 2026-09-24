<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateEjercicioRequest extends FormRequest
{
    /** La ruta ya exige rol Administrador. */
    public function authorize(): bool
    {
        return true;
    }

    /** Edicion parcial con las mismas reglas que el alta; la imagen es opcional. */
    public function rules(): array
    {
        return [
            'nombre' => ['sometimes', 'required', 'string', 'max:100'],
            'descripcion' => ['sometimes', 'nullable', 'string'],
            'tipo' => ['sometimes', 'required', 'in:fuerza,cardio,flexibilidad,equilibrio'],
            'instrucciones' => ['sometimes', 'required', 'string'],
            'nivel' => ['sometimes', 'required', 'in:principiante,intermedio,avanzado'],
            'equipamiento' => ['sometimes', 'required', 'string', 'max:100'],
            'estado' => ['sometimes', 'required', 'boolean'],
            'enlace_video' => ['sometimes', 'nullable', 'string', 'max:350'],
            'imagen_ejercicio' => ['sometimes', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'id_grupos_musculares' => ['sometimes', 'required', 'integer', 'exists:grupos_musculares,id'],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['nivel', 'tipo'] as $campo) {
            if (is_string($this->input($campo))) {
                $this->merge([$campo => mb_strtolower(trim($this->input($campo)))]);
            }
        }
        // FormData envia "undefined"/"" cuando no se elige una imagen nueva.
        if (! $this->hasFile('imagen_ejercicio') && $this->has('imagen_ejercicio')) {
            $this->request->remove('imagen_ejercicio');
        }
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all() + $this->allFiles()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable del ejercicio.');
            }
        }];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos del ejercicio no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
