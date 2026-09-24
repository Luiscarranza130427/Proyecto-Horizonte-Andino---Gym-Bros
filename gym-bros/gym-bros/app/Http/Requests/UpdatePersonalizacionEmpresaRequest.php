<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdatePersonalizacionEmpresaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'color_1' => ['sometimes', 'required', 'string', 'max:10'],
            'color_2' => ['sometimes', 'required', 'string', 'max:10'],
            'banner_1' => $this->hasFile('banner_1') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['sometimes', 'nullable', 'string', 'max:300'],
            'banner_2' => $this->hasFile('banner_2') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['sometimes', 'nullable', 'string', 'max:300'],
            'banner_3' => $this->hasFile('banner_3') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['sometimes', 'nullable', 'string', 'max:300'],
            'link_boton_1' => ['sometimes', 'nullable', 'string', 'max:200'],
            'link_boton_2' => ['sometimes', 'nullable', 'string', 'max:200'],
            'link_boton_3' => ['sometimes', 'nullable', 'string', 'max:200'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un color, banner o enlace de boton.');
            }
        }];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos de personalizacion no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
