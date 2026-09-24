<?php

namespace App\Jobs;

use App\Services\Pagos\CheckoutService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcesarPagoMercadoPago implements ShouldQueue
{
    use Queueable;
    public int $tries = 5;
    public int $timeout = 60;
    public function __construct(public string $paymentId) {}
    public function backoff(): array { return [30,120,600,1800]; }
    public function handle(CheckoutService $service): void
    {
        try { $service->procesar($this->paymentId); }
        catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('No se pudo verificar el pago.', ['payment_id'=>$this->paymentId,'exception'=>get_class($e)]);
            throw new \RuntimeException('Pago pendiente de verificacion; revisar el identificador en el proveedor.');
        }
    }
}
