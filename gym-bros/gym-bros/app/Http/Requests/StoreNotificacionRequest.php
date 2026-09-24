<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreNotificacionRequest extends FormRequest
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
            'tipo' => ['required', 'in:recordatorio,rutina,alimentacion,suscripcion,sistema,otro'],
            'titulo' => ['required', 'string', 'max:150'],
            'mensaje' => ['required', 'string'],
            'fecha_envio' => ['required', 'date'],
            'leida' => ['required', 'boolean'],
            'enviada' => ['required', 'boolean'],
        ];
    }
}
