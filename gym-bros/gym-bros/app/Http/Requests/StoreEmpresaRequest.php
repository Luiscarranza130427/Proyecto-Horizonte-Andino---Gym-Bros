<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class StoreEmpresaRequest extends FormRequest
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
            'id_planes' => ['sometimes', 'nullable', 'integer', Rule::exists('planes', 'id')->where('activo', true)->where(fn ($query) => $query->where('duracion_dias', '>', 0))],
            'nombre' => ['required', 'string', 'max:150'],
            'nombre_gerente' => ['required', 'string', 'max:200'],
            'region' => ['nullable', 'string'],
            'ruc' => ['nullable', 'string', 'max:12'],
            'enlace_web' => ['nullable', 'string', 'max:300'],
            'direccion' => ['nullable', 'string', 'max:250'],
            'telefono' => ['required', 'string', 'max:9'],
            'correo' => ['required', 'email', 'max:150'],
            'estado' => ['required', 'boolean'],
            'fecha_registro' => ['required', 'date'],
            'logo' => $this->hasFile('logo') ? ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'] : ['required', 'string', 'max:300'],
            'color_1' => ['required', 'string', 'max:10'],
            'color_2' => ['required', 'string', 'max:10'],
            'banner_1' => $this->hasFile('banner_1') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['nullable', 'string', 'max:300'],
            'banner_2' => $this->hasFile('banner_2') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['nullable', 'string', 'max:300'],
            'banner_3' => $this->hasFile('banner_3') ? ['image', 'mimes:jpg,jpeg,png,webp', 'max:3072'] : ['nullable', 'string', 'max:300'],
            'link_boton_1' => ['nullable', 'string', 'max:200'],
            'link_boton_2' => ['nullable', 'string', 'max:200'],
            'link_boton_3' => ['nullable', 'string', 'max:200'],
            'horario_inicio_lunes' => ['nullable', 'numeric'],
            'horario_fin_lunes' => ['nullable', 'numeric'],
            'horario_inicio_martes' => ['nullable', 'numeric'],
            'horario_fin_martes' => ['nullable', 'numeric'],
            'horario_inicio_miercoles' => ['nullable', 'numeric'],
            'horario_fin_miercoles' => ['nullable', 'numeric'],
            'horario_inicio_jueves' => ['nullable', 'numeric'],
            'horario_fin_jueves' => ['nullable', 'numeric'],
            'horario_inicio_viernes' => ['nullable', 'numeric'],
            'horario_fin_viernes' => ['nullable', 'numeric'],
            'horario_inicio_sabado' => ['nullable', 'numeric'],
            'horario_fin_sabado' => ['nullable', 'numeric'],
            'horario_inicio_domingo' => ['nullable', 'numeric'],
            'horario_fin_domingo' => ['nullable', 'numeric'],

        ];
    }
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos de la empresa no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
