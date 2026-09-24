<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class EstablecerPasswordRequest extends FormRequest
{
    public function authorize(): bool { return $this->hasValidSignature(); }
    public function rules(): array
    {
        return ['password'=>['required','confirmed','string','max:255',Password::min(12)->letters()->numbers()]];
    }
}
