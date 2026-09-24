<?php

namespace App\Http\Controllers;

use App\Http\Requests\{RecuperarPasswordRequest,RestablecerPasswordRequest};
use App\Jobs\ProcesarRecuperacionPassword;
use App\Services\Auth\PasswordRecoveryService;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class PasswordRecoveryController extends Controller
{
    public function forgot(RecuperarPasswordRequest $request)
    {
        $correo = $request->validated('correo');
        try {
            RateLimiter::attempt('recuperar-cuenta:'.hash('sha256', $correo), 1, function () use ($correo) {
                ProcesarRecuperacionPassword::dispatch($correo)->onConnection('database')->onQueue('recuperacion-password');
            }, 60);
        } catch (\Throwable $e) {
            return $this->fallo($e);
        }

        return response()->json(['message'=>'Si existe una cuenta con ese correo, recibirás las instrucciones para recuperar tu contraseña.']);
    }

    public function reset(RestablecerPasswordRequest $request, PasswordRecoveryService $service)
    {
        try { $ok = $service->restablecer($request->validated()); }
        catch (\Throwable $e) { return $this->fallo($e); }
        if (! $ok) {
            throw ValidationException::withMessages(['token'=>['El enlace no es válido o ha vencido. Solicita uno nuevo.']]);
        }
        return response()->json(['message'=>'Contraseña actualizada correctamente. Inicia sesión nuevamente.']);
    }

    private function fallo(\Throwable $e)
    {
        Log::error('Recuperacion temporalmente no disponible.', ['exception'=>get_class($e)]);
        return response()->json(['message'=>'El servicio no esta disponible temporalmente.'],503);
    }
}
