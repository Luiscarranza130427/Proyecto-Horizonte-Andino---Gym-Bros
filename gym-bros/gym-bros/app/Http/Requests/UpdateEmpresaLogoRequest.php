<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateEmpresaLogoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['logo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120']];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'El logo debe ser una imagen JPG, JPEG, PNG o WebP de hasta 5 MB.',
            'errors' => $validator->errors(),
        ], 422));
    }
}
