<?php

namespace App\Http\Responses;

use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class ErrorAlimentacionResponse
{
    public function __invoke(Response $response, Throwable $exception, Request $request): Response
    {
        if (! $request->is('api/alimentos', 'api/alimentos/*/nutricion', 'api/restriccionesalimentarias',
            'api/usuarios/*/perfil-alimentario', 'api/planesalimentacion/generar/*', 'api/usuarios/*/planesalimentacion/*')) {
            return $response;
        }
        $status = $response->getStatusCode();
        if ($exception instanceof ValidationException) {
            return response()->json(['message' => 'Los datos de alimentacion no son validos.', 'errors' => $exception->errors()], 422);
        }
        if ($status === 422 && $response instanceof \Illuminate\Http\JsonResponse) {
            return $response;
        }
        $mensaje = match ($status) {
            401 => 'Se requiere autenticacion.',
            403 => 'No tiene autorizacion para este usuario.',
            404 => 'El recurso solicitado no existe o no pertenece al usuario.',
            405 => 'Metodo HTTP no permitido.',
            503 => 'El servicio de alimentacion no esta disponible temporalmente.',
            default => $status >= 500 ? 'No se pudo completar la operacion de alimentacion.' : 'La solicitud no pudo procesarse.',
        };

        return response()->json(['message' => $mensaje, 'errors' => ['solicitud' => [$mensaje]]], $status);
    }
}
