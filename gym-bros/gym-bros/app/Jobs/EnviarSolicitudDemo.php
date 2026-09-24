<?php

namespace App\Jobs;

use App\Mail\SolicitudDemo;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\{DB,Log,Mail};

class EnviarSolicitudDemo implements ShouldQueue
{
    use Queueable;
    public int $tries = 5;
    public int $timeout = 60;
    public function __construct(public int $solicitudId) {}
    public function backoff(): array { return [60,300,900,3600]; }

    public function handle(): void
    {
        try {
            $solicitud = DB::table('solicitudes_demo')->find($this->solicitudId);
            if (!$solicitud) { throw new \RuntimeException('Solicitud no encontrada.'); }
            Mail::mailer('smtp')->to('info@novawavedev.com')->send(new SolicitudDemo($solicitud));
        } catch (\Throwable $e) {
            Log::error('Envio de solicitud demo pendiente.', ['solicitud_id'=>$this->solicitudId, 'exception'=>get_class($e)]);
            throw new \RuntimeException('No se pudo enviar la notificacion de demostracion.');
        }
    }
}
