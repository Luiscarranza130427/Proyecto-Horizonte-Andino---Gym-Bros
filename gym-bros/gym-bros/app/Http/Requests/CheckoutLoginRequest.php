<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CheckoutLoginRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return ['correo'=>['required','email','not_regex:/[\x00-\x1F\x7F]/','max:255'],
            'password'=>['required','string','max:255']];
    }
}
