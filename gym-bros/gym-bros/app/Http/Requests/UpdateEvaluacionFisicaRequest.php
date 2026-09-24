<?php

namespace App\Http\Requests;

class UpdateEvaluacionFisicaRequest extends StoreEvaluacionFisicaRequest
{
    public function rules(): array
    {
        $rules = parent::rules();
        unset($rules['id_usuarios']);

        // Validate the final day count against the saved evaluation inside the transaction.
        $rules['eleccion_dias'] = ['nullable', 'array'];
        foreach ($rules as $field => $fieldRules) {
            if (! str_contains($field, '.*')) {
                array_unshift($fieldRules, 'sometimes');
                $rules[$field] = $fieldRules;
            }
        }

        return $rules;
    }
}
