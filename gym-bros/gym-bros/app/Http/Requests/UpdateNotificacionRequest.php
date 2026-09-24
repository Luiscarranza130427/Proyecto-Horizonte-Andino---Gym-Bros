<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNotificacionRequest extends FormRequest
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
        return [
            'id_empresas' => ['nullable', 'integer', 'exists:empresas,id'],
            'id_usuarios' => ['nullable', 'integer', 'exists:usuarios,id'],
            'tipo' => ['nullable', 'in:recordatorio,rutina,alimentacion,suscripcion,sistema,otro'],
            'titulo' => ['nullable', 'string', 'max:150'],
            'mensaje' => ['nullable', 'string'],
            'fecha_envio' => ['nullable', 'date'],
            'leida' => ['nullable', 'boolean'],
            'enviada' => ['nullable', 'boolean'],
        ];
    }
}
