<?php

namespace App\Http\Requests;

class RecuperarPasswordRequest extends LoginRequest
{
    public function rules(): array
    {
        return ['correo' => parent::rules()['correo']];
    }
}
