<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rules\Password;

class RestablecerPasswordRequest extends RecuperarPasswordRequest
{
    public function rules(): array
    {
        return array_merge(parent::rules(), [
            'token' => ['required', 'string', 'size:64', 'regex:/^[a-f0-9]{64}$/'],
            'password' => ['required', 'string', 'max:255', 'confirmed', Password::min(12)->letters()->numbers()],
        ]);
    }
}
