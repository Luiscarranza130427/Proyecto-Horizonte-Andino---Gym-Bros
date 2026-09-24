<?php

namespace App\Services\Usuarios;

use App\Jobs\ProcesarRecuperacionPassword;
use App\Models\{Empresa,Usuario};
use Illuminate\Support\Facades\{DB,Queue,Validator};
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ImportarUsuariosService
{
    public function importar(array $filas, int $empresaId): int
    {
        $errores = []; $correos = [];
        foreach ($filas as $numero=>&$fila) {
            $fila['correo'] = mb_strtolower($fila['correo'] ?? '');
            $fila['fecha_registro'] = $fila['fecha_registro'] ?? now()->toDateString();
            $rules = [
                'nombres'=>['required','string','max:100'], 'apellidos'=>['required','string','max:100'],
                'apodo'=>['required','string','max:100'], 'genero'=>['required','in:Varon,Mujer'],
                'correo'=>['required','email','max:255','not_regex:/[\x00-\x1F\x7F]/'],
                'tipo_documento'=>['required','in:DNI,PASAPORTE,OTRO'],
                'numero_documento'=>['required','string','max:12'], 'telefono'=>['required','string','max:12'],
                'fecha_nacimiento'=>['required','date_format:Y-m-d','after_or_equal:1000-01-01','before_or_equal:today'],
                'fecha_registro'=>['required','date_format:Y-m-d','after_or_equal:1000-01-01','before_or_equal:today','after_or_equal:fecha_nacimiento'],
                'direccion'=>['nullable','string','max:150'],
                'inicio_suscripcion'=>['nullable','date_format:Y-m-d','after_or_equal:1000-01-01'],
                'fin_suscripcion'=>['nullable','date_format:Y-m-d','after_or_equal:1000-01-01'],
            ];
            if (!empty($fila['inicio_suscripcion'])) { $rules['fin_suscripcion'][] = 'after_or_equal:inicio_suscripcion'; }
            $validator = Validator::make($fila,$rules);
            foreach ($validator->errors()->toArray() as $campo=>$mensajes) { $errores["filas.$numero.$campo"] = $mensajes; }
            if (isset($correos[$fila['correo']])) {
                $errores["filas.$numero.correo"] = ['Correo repetido dentro del archivo.'];
            }
            $correos[$fila['correo']] = $numero;
        }
        unset($fila);
        if ($errores) { throw ValidationException::withMessages($errores); }

        return DB::transaction(function () use ($filas,$empresaId) {
            if (!Empresa::whereKey($empresaId)->lockForUpdate()->exists()) {
                throw ValidationException::withMessages(['id_empresas'=>['La empresa no existe.']]);
            }
            $correos = array_column($filas,'correo');
            $existentes = Usuario::whereIn(DB::raw('LOWER(TRIM(correo))'),$correos)->lockForUpdate()
                ->pluck('correo')->map(fn ($c)=>mb_strtolower(trim($c)))->all();
            $errores = [];
            foreach ($filas as $numero=>$fila) {
                if (in_array($fila['correo'],$existentes,true)) { $errores["filas.$numero.correo"] = ['El correo ya esta registrado. No se actualizan usuarios existentes.']; }
            }
            if ($errores) { throw ValidationException::withMessages($errores); }
            $queue = Queue::connection('database');
            if ($queue->getDatabase() !== DB::connection()) { throw new \RuntimeException('La cola debe usar la misma base de datos.'); }
            foreach ($filas as $numero=>$fila) {
                // No usable password exists until the owner follows the emailed reset link.
                $fila['password_hash'] = '!pendiente:'.Str::random(64);
                $fila['tipo_usuario'] = 'Usuario'; $fila['estado'] = true; $fila['id_empresas'] = $empresaId;
                try { Usuario::create($fila); }
                catch (\Illuminate\Database\UniqueConstraintViolationException) {
                    throw ValidationException::withMessages(["filas.$numero.correo"=>['El correo ya esta registrado.']]);
                }
                $queue->push((new ProcesarRecuperacionPassword($fila['correo'], true))->beforeCommit(), '', 'recuperacion-password');
            }
            return count($filas);
        });
    }
}
