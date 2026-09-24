<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateAlimentoRequest extends FormRequest
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
        $rules = [
            'nombre' => ['sometimes', 'required', 'string', 'max:150'],
            'tipo' => ['sometimes', 'required', 'in:proteina,carbohidrato,grasa,fruta,verdura,lacteo,cereal,legumbre,bebida,otro'],
            'activo' => ['sometimes', 'required', 'boolean'],
        ];
        $nutricion = (new ActualizarNutricionAlimentoRequest())->rules();
        foreach ($nutricion as $campo => $validaciones) {
            if ($campo === 'restricciones') {
                continue;
            }
            // Compare portion bounds against the locked record in the controller.
            $validaciones = array_values(array_diff($validaciones, ['present', 'gte:porcion_min']));
            $rules[$campo] = str_contains($campo, '.') ? $validaciones : array_merge(['sometimes'], $validaciones);
        }

        return $rules;
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable del alimento.');
            }
        }];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos del alimento no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
