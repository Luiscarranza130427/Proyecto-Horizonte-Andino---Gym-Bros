<?php

namespace App\Http\Requests;

use App\Models\Plan;
use Illuminate\Foundation\Http\FormRequest;

class UpdatePlanRequest extends FormRequest
{
    /** La ruta ya exige rol Administrador (acceso:rol,Administrador). */
    public function authorize(): bool
    {
        return true;
    }

    /** Edicion parcial: lo omitido se conserva, pero un campo obligatorio no admite null. */
    public function rules(): array
    {
        $original = $this->input('precio_original', Plan::whereKey($this->route('id_plan'))->value('precio_original'));

        return [
            'nombre' => ['sometimes', 'required', 'string', 'max:100'],
            'descripcion' => ['sometimes', 'required', 'string', 'max:2000'],
            'precio_original' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0', 'max:9999999'],
            'precio_inicial' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0', 'max:9999999',
                ...(is_numeric($original) ? ['max:'.$original] : [])],
            'duracion_dias' => ['sometimes', 'required', 'integer', 'between:1,3650'],
            'limite_usuarios' => ['sometimes', 'required', 'integer', 'between:1,1000000'],
            'activo' => ['sometimes', 'required', 'boolean'],
            'contenido' => ['sometimes', 'nullable', 'string', 'max:5000'],
            'enlace_whatsapp' => ['sometimes', 'required', 'url:http,https', 'max:300'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable del plan.');
            }
        }];
    }
}
