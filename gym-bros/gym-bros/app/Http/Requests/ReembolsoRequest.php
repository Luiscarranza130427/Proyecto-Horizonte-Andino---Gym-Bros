<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReembolsoRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array { return ['motivo'=>['required','string','max:500']]; }
}
