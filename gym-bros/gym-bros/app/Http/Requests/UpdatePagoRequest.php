<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePagoRequest extends FormRequest
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
            'id_suscripciones' => ['required', 'integer', 'exists:suscripciones,id'],
            'monto' => ['nullable', 'numeric'],
            'moneda' => ['nullable', 'string', 'size:3'],
            'metodo_pago' => ['nullable', 'string', 'max:50'],
            'referencia' => ['nullable', 'string', 'max:255'],
            'estado' => ['nullable', 'in:pendiente,aprobado,rechazado,reembolsado'],
            'fecha_pago' => ['nullable', 'date']
        ];
    }
}
