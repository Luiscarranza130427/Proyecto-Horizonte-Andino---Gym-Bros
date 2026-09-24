<?php

namespace App\Http\Requests;

class UpdateBannerRequest extends StoreBannerRequest
{
    public function rules(): array
    {
        return array_map(fn ($rules) => array_merge(['sometimes'], $rules), parent::rules());
    }

    public function after(): array
    {
        return [function ($validator) {
            if (array_intersect(array_keys($this->all()), array_keys($this->rules())) === []) {
                $validator->errors()->add('datos', 'Envie al menos un campo editable del banner.');
            }
        }];
    }
}
