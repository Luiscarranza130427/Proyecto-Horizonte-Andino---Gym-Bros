<?php

namespace App\Http\Requests;

use App\Models\Usuario;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class ImportarUsuariosRequest extends FormRequest
{
    public function authorize(): bool
    {
        $actor = $this->user('sanctum');
        return $actor instanceof Usuario && $actor->estado && in_array($actor->tipo_usuario, ['Administrador','Empresa'], true);
    }

    public function rules(): array
    {
        return [
            'archivo' => ['required','file','max:5120','extensions:csv,xlsx',
                'mimetypes:text/plain,text/csv,application/csv,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/zip'],
            'id_empresas' => $this->user('sanctum')->tipo_usuario === 'Administrador'
                ? ['required','integer',Rule::exists('empresas','id')]
                : ['prohibited'],
        ];
    }

    protected function failedValidation(\Illuminate\Contracts\Validation\Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'message'=>'No se importo ningun usuario. Corrige los errores del archivo o formulario.',
            'errors'=>$validator->errors(),
        ],422));
    }

    protected function failedAuthorization(): void
    {
        throw new HttpResponseException(response()->json(['message'=>'No tiene permiso para importar usuarios.'],403));
    }
}
