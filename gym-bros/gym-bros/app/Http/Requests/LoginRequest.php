<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('correo'))) {
            $this->merge(['correo'=>mb_strtolower(trim($this->input('correo')))]);
        }
    }

    public function rules(): array
    {
        return ['correo'=>['required','string','email','max:255','not_regex:/[\x00-\x1F\x7F]/'],
            'password'=>['required','string','max:255']];
    }
}
