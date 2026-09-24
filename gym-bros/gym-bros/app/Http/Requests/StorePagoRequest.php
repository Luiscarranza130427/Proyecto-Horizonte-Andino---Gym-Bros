<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePagoRequest extends FormRequest
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
            'monto' => ['required', 'numeric'],
            'moneda' => ['required', 'string', 'size:3'],
            'metodo_pago' => ['required', 'string', 'max:50'],
            'referencia' => ['required', 'string', 'max:255'],
            'estado' => ['required', 'in:pendiente,aprobado,rechazado,reembolsado'],
            'fecha_pago' => ['required', 'date']
        ];
    }
}
