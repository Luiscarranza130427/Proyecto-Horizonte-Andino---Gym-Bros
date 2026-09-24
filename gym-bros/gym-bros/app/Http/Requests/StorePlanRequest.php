<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePlanRequest extends FormRequest
{
    /** La ruta ya exige rol Administrador (acceso:rol,Administrador). */
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:100'],
            'descripcion' => ['required', 'string', 'max:2000'],
            'precio_original' => ['required', 'numeric', 'decimal:0,2', 'min:0', 'max:9999999'],
            'precio_inicial' => ['required', 'numeric', 'decimal:0,2', 'min:0', 'max:9999999', 'lte:precio_original'],
            'duracion_dias' => ['required', 'integer', 'between:1,3650'],
            'limite_usuarios' => ['required', 'integer', 'between:1,1000000'],
            'activo' => ['required', 'boolean'],
            'contenido' => ['nullable', 'string', 'max:5000'],
            'enlace_whatsapp' => ['required', 'url:http,https', 'max:300'],
        ];
    }

    public function messages(): array
    {
        return ['precio_inicial.lte' => 'El precio con descuento no puede superar al precio original.'];
    }
}
