<?php

namespace App\Http\Controllers;

use App\Http\Requests\SolicitudDemoRequest;
use App\Jobs\EnviarSolicitudDemo;
use Illuminate\Support\Facades\{DB,Log};

class SolicitudDemoController extends Controller
{
    public function store(SolicitudDemoRequest $request)
    {
        try {
            $id = DB::transaction(function () use ($request) {
                $id = DB::table('solicitudes_demo')->insertGetId([
                    'correo' => $request->validated()['correo'],
                    'ip' => $request->ip(),
                    'user_agent' => $request->userAgent() === null ? null : mb_substr($request->userAgent(), 0, 2000),
                    'estado' => 'pendiente', 'created_at' => now(), 'updated_at' => now(),
                ]);
                // Use the same DB transaction for the request and its queued notification.
                $queue = \Illuminate\Support\Facades\Queue::connection('database');
                if ($queue->getDatabase() !== DB::connection()) {
                    throw new \RuntimeException('La cola requiere la misma conexion de base de datos.');
                }
                $job = (new EnviarSolicitudDemo($id))->beforeCommit();
                $queue->push($job, '', 'solicitudes-demo');
                return $id;
            });
        } catch (\Throwable $e) {
            Log::error('No se pudo registrar solicitud demo.', ['exception' => get_class($e)]);
            return response()->json(['message' => 'No pudimos registrar la solicitud en este momento.'], 503);
        }

        return response()->json(['data' => ['id' => $id, 'estado' => 'pendiente',
            'mensaje' => 'Solicitud registrada correctamente.']], 201);
    }
}
