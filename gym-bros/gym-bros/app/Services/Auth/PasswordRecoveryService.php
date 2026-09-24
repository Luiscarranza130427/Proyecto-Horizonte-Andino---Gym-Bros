<?php

namespace App\Services\Auth;

use App\Jobs\EnviarRecuperacionPassword;
use App\Models\Usuario;
use Illuminate\Support\Facades\{DB,Hash,Password,Queue};

class PasswordRecoveryService
{
    private function cuenta(string $correo): ?Usuario
    {
        $cuentas = Usuario::whereRaw('LOWER(TRIM(correo)) = ?', [$correo])->orderBy('id')->limit(2)->lockForUpdate()->get();
        return $cuentas->count() === 1 ? $cuentas->first() : null;
    }

    public function generar(string $correo, bool $alta = false): void
    {
        DB::transaction(function () use ($correo, $alta) {
            $usuario = $this->cuenta($correo);
            if (! $usuario) { return; }
            $broker = Password::broker('usuarios');
            if ($broker->getRepository()->recentlyCreatedToken($usuario)) { return; }
            $token = $broker->createToken($usuario);
            $queue = Queue::connection('database');
            if ($queue->getDatabase() !== DB::connection()) {
                throw new \RuntimeException('La recuperacion requiere cola en la misma base de datos.');
            }
            // Token replacement and its encrypted mail job commit together.
            $queue->push((new EnviarRecuperacionPassword($usuario->id, $correo, $token, $alta))->beforeCommit(), '', 'recuperacion-password');
        });
    }

    public function restablecer(#[\SensitiveParameter] array $datos): bool
    {
        return DB::transaction(function () use ($datos) {
            $usuario = $this->cuenta($datos['correo']);
            if (! $usuario) { return false; }
            $broker = Password::broker('usuarios');
            if (! $broker->tokenExists($usuario, $datos['token'])) { return false; }
            $usuario->password_hash = Hash::make($datos['password']);
            if (! $usuario->save()) { throw new \RuntimeException('No se pudo restablecer la cuenta.'); }
            $usuario->tokens()->delete();
            $broker->deleteToken($usuario);
            return true;
        });
    }
}
