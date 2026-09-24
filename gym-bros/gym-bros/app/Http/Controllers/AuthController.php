<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequest;
use App\Http\Resources\UsuarioResource;
use App\Models\Usuario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB,Hash};

class AuthController extends Controller
{
    public function login(LoginRequest $request)
    {
        $datos = $request->validated();
        // Reject ambiguous legacy duplicate emails instead of choosing an account.
        $usuarios = Usuario::whereRaw('LOWER(TRIM(correo)) = ?', [$datos['correo']])->limit(2)->get();
        $usuario = $usuarios->count() === 1 ? $usuarios->first() : null;
        $hash = $usuario?->password_hash;
        if (! is_string($hash) || ! password_get_info($hash)['algo']) {
            $hash = '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
            $usuario = null;
        }
        try { $valida = Hash::check($datos['password'], $hash); }
        catch (\RuntimeException) { $valida = false; }
        if (! $usuario || ! $valida) {
            return response()->json(['message'=>'Correo o contrasena incorrectos.'],401);
        }
        if (! $usuario->estado) {
            return response()->json(['message'=>'La cuenta esta inactiva.'],403);
        }
        $expira = now()->addHours(8);
        $token = DB::transaction(function () use ($usuario,$datos,$expira) {
            // Serialize issuance with password recovery and its session revocation.
            $actual = Usuario::whereKey($usuario->id)->lockForUpdate()->first();
            if (! $actual || ! $actual->estado || ! hash_equals($usuario->password_hash, $actual->password_hash)) {
                return null;
            }
            if (Hash::needsRehash($actual->password_hash)) {
                $actual->password_hash = Hash::make($datos['password']);
                $actual->save();
            }
            return $actual->createToken('sesion', ['sesion'], $expira);
        });
        if (! $token) {
            return response()->json(['message'=>'Correo o contrasena incorrectos.'],401);
        }
        return response()->json(['data'=>[
            'token'=>$token->plainTextToken,'token_type'=>'Bearer','expires_at'=>$expira->toIso8601String(),
            'usuario'=>new UsuarioResource($usuario),
        ]]);
    }

    public function me(Request $request)
    {
        return response()->json(['data'=>new UsuarioResource($request->user('sanctum'))]);
    }

    public function logout(Request $request)
    {
        $request->user('sanctum')->currentAccessToken()?->delete();
        return response()->json(['message'=>'Sesion cerrada correctamente.']);
    }

    /**
     * Cambio de contrasena con la actual. Misma politica que la recuperacion
     * (12+ caracteres con letras y numeros) y revoca las demas sesiones.
     */
    public function cambiarContrasena(Request $request)
    {
        $datos = $request->validate([
            'password_actual' => ['required', 'string', 'max:255'],
            'password_nuevo' => ['required', 'string', 'max:255', 'different:password_actual',
                \Illuminate\Validation\Rules\Password::min(12)->letters()->numbers()],
            'password_confirmacion' => ['required', 'same:password_nuevo'],
        ]);
        $usuario = $request->user('sanctum');
        $token = $usuario->currentAccessToken();
        $actual = $token instanceof \Laravel\Sanctum\PersonalAccessToken ? $token : null;
        $valida = DB::transaction(function () use ($usuario, $datos, $actual) {
            $registro = Usuario::whereKey($usuario->getKey())->lockForUpdate()->first();
            try { $ok = Hash::check($datos['password_actual'], (string) $registro->password_hash); }
            catch (\RuntimeException) { $ok = false; }
            if (! $ok) {
                return false;
            }
            $registro->password_hash = Hash::make($datos['password_nuevo']);
            $registro->save();
            $registro->tokens()->when($actual?->getKey(), fn ($q, $id) => $q->whereKeyNot($id))->delete();
            return true;
        });
        if (! $valida) {
            return response()->json(['message'=>'La contrasena actual no es correcta.',
                'errors'=>['password_actual'=>['La contrasena actual no es correcta.']]],422);
        }
        return response()->json(['message'=>'Contrasena actualizada. Las demas sesiones se cerraron.']);
    }

    /** Revoca todos los tokens del usuario salvo el de esta sesion. */
    public function cerrarOtrasSesiones(Request $request)
    {
        $usuario = $request->user('sanctum');
        $token = $usuario->currentAccessToken();
        $actual = $token instanceof \Laravel\Sanctum\PersonalAccessToken ? $token->getKey() : null;
        $cerradas = $usuario->tokens()->when($actual, fn ($q, $id) => $q->whereKeyNot($id))->delete();
        return response()->json(['message'=>'Otras sesiones cerradas.','data'=>['sesiones_cerradas'=>$cerradas]]);
    }
}
