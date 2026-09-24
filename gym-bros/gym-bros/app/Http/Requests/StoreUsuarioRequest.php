<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUsuarioRequest extends FormRequest
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
            'nombres' => ['required', 'string', 'max:100'],
            'apellidos' => ['required', 'string', 'max:100'],
            'apodo' =>['required','string','max:100'],
            'genero' => ['required', 'in:Varon,Mujer'],
            'correo' => ['required', 'email', 'max:255', 'regex:/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/i', Rule::unique('usuarios')->where(function ($query) {
        return $query->where('estado', 1);
    })
],
            'password_hash' => ['required', 'string', 'min:8'],
            'tipo_documento' => ['required', 'in:DNI,PASAPORTE,OTRO'],
            'numero_documento' => ['required', 'string', 'max:12'],
            'telefono' => ['required', 'string', 'max:12'],
            'direccion' => ['nullable', 'string', 'max:150'],
            'foto_perfil' => ['nullable', 'string', 'max:250'],
            'fecha_registro' => ['required', 'date'],
            'fecha_nacimiento' => ['required', 'date'],
            'asistencia_semanal' => ['nullable', 'date'],
            'inicio_suscripcion' => ['nullable', 'date'],
            'fin_suscripcion' => ['nullable', 'date'],
            'tipo_usuario' => ['required', 'in:Administrador,Empresa,Entrenador,Usuario'],
            'estado' => ['required', 'boolean'],
            'id_empresas' => ['nullable', 'integer', 'exists:empresas,id'],
        ];
    }
}
