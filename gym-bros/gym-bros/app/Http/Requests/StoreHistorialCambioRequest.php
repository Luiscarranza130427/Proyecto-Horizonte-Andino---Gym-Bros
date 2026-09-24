<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreHistorialCambioRequest extends FormRequest
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
            'id_usuarios' => ['required', 'integer', 'exists:usuarios,id'],
            'tabla_afectada' => ['required', 'string', 'max:100'],
            'id_registros' => ['required', 'integer'],
            'accion' => ['required', 'in:crear,actualizar,eliminar,activar,desactivar'],
            'datos_anteriores' => ['required', 'json'],
            'datos_nuevos' => ['required', 'json'],
            'descripcion' => ['required', 'string'],
        ];
    }
}
