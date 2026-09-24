<?php

namespace App\Http\Requests;

class GuardarPerfilAlimentarioRequest extends SolicitudAlimentacionRequest
{
    public function rules(): array
    {
        return [
            'sexo_calculo' => ['required', 'in:masculino,femenino'],
            'embarazo' => ['required', 'boolean'],
            'lactancia' => ['required', 'boolean'],
            'requiere_plan_clinico' => ['required', 'boolean'],
            'apto_plan_general' => ['required', 'boolean'],
            'revision_profesional' => ['sometimes', 'nullable', 'string', 'max:200'],
            'revisado_en' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:1000-01-01', 'before_or_equal:today'],
            'alergias' => ['sometimes', 'array', 'max:0'],
            'intolerancias' => ['sometimes', 'array', 'max:0'],
            'preferencias' => ['present', 'array', 'max:'.\App\Models\Alimento::count()],
            'preferencias.*' => ['array:id_alimentos,tipo'],
            'preferencias.*.id_alimentos' => ['required', 'integer', 'distinct', 'exists:alimentos,id'],
            'preferencias.*.tipo' => ['required', 'in:preferido,rechazado'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if ($this->input('sexo_calculo') === 'masculino') {
                foreach (['embarazo', 'lactancia'] as $campo) {
                    if ($this->boolean($campo)) {
                        $validator->errors()->add($campo, 'Debe ser false cuando sexo_calculo es masculino.');
                    }
                }
            }
        }];
    }

    public function messages(): array
    {
        return [
            'alergias.max' => 'Este formulario solo admite preferencias por alimento; omita alergias o envie [].',
            'intolerancias.max' => 'Este formulario solo admite preferencias por alimento; omita intolerancias o envie [].',
        ];
    }
}
