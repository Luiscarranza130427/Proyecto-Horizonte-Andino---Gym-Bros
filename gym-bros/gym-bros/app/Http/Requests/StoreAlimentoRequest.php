<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAlimentoRequest extends FormRequest
{
    /** La ruta ya exige rol Administrador. */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Nombre, tipo y macronutrientes son obligatorios. Los datos para el
     * generador de planes (base, porciones, grupo de menu...) son opcionales
     * con las mismas reglas que la edicion; si se envian, se validan juntos.
     */
    public function rules(): array
    {
        $reglas = (new UpdateAlimentoRequest())->rules();
        foreach (['nombre', 'tipo', 'calorias', 'proteinas', 'carbohidratos', 'grasas', 'fibra'] as $campo) {
            $reglas[$campo] = array_values(array_diff($reglas[$campo], ['sometimes']));
        }

        return $reglas;
    }
}
