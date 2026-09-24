<?php

namespace App\Http\Middleware;

use App\Models\Usuario;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{Auth,Log};
use Illuminate\Validation\ValidationException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

class ApiSesion
{
    public function handle(Request $request, Closure $next, string $modo = 'protegido')
    {
        $request->headers->set('Accept', 'application/json');
        try {
            if (app()->environment('production') && ! $request->isSecure()) {
                return response()->json(['message'=>'Se requiere HTTPS.'],400);
            }
            if ($modo !== 'publico') {
                Auth::shouldUse('sanctum');
                $usuario = $request->user('sanctum');
                if (! $usuario instanceof Usuario || ! $usuario->tokenCan('sesion')) {
                    return response()->json(['message'=>'Sesion no valida o expirada.'],401);
                }
                if (! $usuario->estado) {
                    return response()->json(['message'=>'La cuenta esta inactiva.'],403);
                }
            }
            $response = $next($request);
            $response->headers->set('Cache-Control','no-store');
            return $response;
        } catch (ValidationException $e) {
            return response()->json(['message'=>'Los datos proporcionados no son validos.','errors'=>$e->errors()],422);
        } catch (HttpResponseException $e) {
            return $e->getResponse();
        } catch (HttpExceptionInterface $e) {
            return response()->json(['message'=>'No se pudo procesar la solicitud.'],$e->getStatusCode(),$e->getHeaders());
        } catch (\Throwable $e) {
            Log::error('Fallo de API de sesion.', ['exception'=>get_class($e)]);
            return response()->json(['message'=>'El servicio no esta disponible temporalmente.'],503);
        }
    }
}
