<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSuscripcionRequest extends FormRequest
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
            'id_empresas' => ['required', 'integer', 'exists:empresas,id'],
            'id_planes' => ['required', 'integer', 'exists:planes,id'],
            'fecha_inicio' => ['required', 'date'],
            'fecha_fin' => ['required', 'date'],
            'estado' => ['required', 'in:pendiente,activa,vencida,cancelada,suspendida'],
            'renovacion_automatica' => ['required', 'boolean'],
        ];
    }
}
