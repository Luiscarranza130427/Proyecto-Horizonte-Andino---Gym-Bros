<?php

namespace App\Http\Requests;

use App\Models\Usuario;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreEvaluacionFisicaRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if ($this->route('id_usuario') !== null) {
            $usuario = Usuario::select('id')->findOrFail($this->route('id_usuario'));
            $this->merge(['id_usuarios' => $usuario->id]);
        }
    }

    public function messages(): array
    {
        return ['altura.between' => 'La altura debe expresarse en centimetros, entre 30 y 250.'];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Los datos de la evaluacion fisica no son validos.',
            'errors' => $validator->errors(),
        ], 422));
    }

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
            'id_usuarios' => ['required', 'integer', 'exists:usuarios,id'],
            'nivel_experiencia' => ['required', 'in:1a3meses,4a8meses,1ano,mas1ano,2anos,3anos_mas,3anosamas'],
            'actividad_diaria' => ['required', 'in:sedentario,activo_ligero,moderadamente_activo,muy_activo'],
            'objetivo' => ['required', 'in:perdida_peso,ganancia_muscular,resistencia,recomposicion,aumento_fuerza,salud'],
            'edad' => ['required', 'integer', 'between:1,2147483647'],
            'peso' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'altura' => \Illuminate\Support\Facades\Schema::hasColumn('evaluaciones_fisicas', 'altura_unidad')
                ? ['required', 'numeric', 'decimal:0,2', 'between:30,250']
                : ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:999.99'],
            'porcentaje_grasa' => ['required', 'numeric', 'decimal:0,2', 'between:0,100'],
            'masa_muscular' => ['required', 'numeric', 'decimal:0,2', 'between:0,9999.99'],
            'cintura' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'pecho' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'brazo' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'muslo' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'cadera' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:9999.99'],
            'dias_semana' => ['required', 'integer', 'between:2,6'],
            'eleccion_dias' => ['nullable', 'array', 'size:'.(is_numeric($this->input('dias_semana')) ? (int) $this->input('dias_semana') : 0)],
            'eleccion_dias.*' => ['required', 'distinct', 'in:Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo'],
            'tiempo_sesion_min' => ['required', 'integer', 'between:1,180'],
            'restricciones' => ['required', 'in:sin-restricciones,manco,cojo,paralitico,movilidad-reducida,amputacion-de-extremidad,silla-de-ruedas,uso-de-muletas,uso-de-baston,uso-de-andador,limitacion-de-brazos,limitacion-de-piernas,problemas-de-equilibrio,problemas-de-coordinacion,lesion-reciente,cirugia-reciente,dolor-musculoesqueletico,limitacion-cardiovascular,limitacion-respiratoria,discapacidad-visual,discapacidad-auditiva'],
            'fecha_evaluacion' => ['required', 'date_format:Y-m-d', 'after_or_equal:1000-01-01', 'before_or_equal:today'],
        ];
    }
}
