<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class UpdateEmpresaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $rules = [
            'id_planes' => ['sometimes', 'nullable', 'integer', Rule::exists('planes', 'id')->where('activo', true)->where(fn ($query) => $query->where('duracion_dias', '>', 0))],
            'nombre' => ['sometimes', 'required', 'string', 'max:150'],
            'nombre_gerente' => ['sometimes', 'required', 'string', 'max:200'],
            'region' => ['sometimes', 'nullable', Rule::in(['Amazonas', 'Ancash', 'Apurimac', 'Arequipa',
                'Ayacucho', 'Cajamarca', 'Callao', 'Cusco', 'Huancavelica', 'Huanuco', 'Ica', 'Junin',
                'La Libertad', 'Lambayeque', 'Lima', 'Loreto', 'Madre de Dios', 'Moquegua', 'Pasco',
                'Piura', 'Puno', 'San Martin', 'Tacna', 'Tumbes', 'Ucayali'])],
            'ruc' => ['sometimes', 'nullable', 'string', 'max:12'],
            'enlace_web' => ['sometimes', 'nullable', 'string', 'max:300'],
            'direccion' => ['sometimes', 'nullable', 'string', 'max:250'],
            'telefono' => ['sometimes', 'required', 'string', 'max:9'],
            'correo' => ['sometimes', 'required', 'email', 'max:150', 'not_regex:/[\x00-\x1F\x7F]/'],
            'estado' => ['sometimes', 'required', 'boolean'],
            'fecha_registro' => ['sometimes', 'required', 'date_format:Y-m-d', 'after_or_equal:1000-01-01'],
            'logo' => ['sometimes', 'required', 'string', 'max:300'],
        ];
        foreach (['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'] as $dia) {
            foreach (['inicio', 'fin'] as $extremo) {
                // Solo el fin de semana puede quedar sin horario (docs/editar-empresa.md).
                $rules['horario_'.$extremo.'_'.$dia] = ['sometimes',
                    in_array($dia, ['sabado', 'domingo'], true) ? 'nullable' : 'required',
                    'numeric', 'decimal:0,2', 'between:0,24'];
            }
        }

        return $rules;
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable de la empresa.');
            }
        }];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos de la empresa no son validos.', 'errors' => $validator->errors(),
        ], 422));
    }
}
