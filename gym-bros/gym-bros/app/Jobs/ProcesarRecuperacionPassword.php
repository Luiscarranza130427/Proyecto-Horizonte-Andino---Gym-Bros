<?php

namespace App\Jobs;

use App\Services\Auth\PasswordRecoveryService;
use Illuminate\Contracts\Queue\{ShouldQueue,ShouldBeEncrypted};
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class ProcesarRecuperacionPassword implements ShouldQueue, ShouldBeEncrypted
{
    use Queueable;
    public int $tries = 5;
    public int $timeout = 60;
    public bool $alta = false;
    public function __construct(private string $correo, bool $alta = false) { $this->alta = $alta; }
    public function backoff(): array { return [60,300,900,1800]; }

    public function handle(PasswordRecoveryService $service): void
    {
        try { $service->generar($this->correo, $this->alta); }
        catch (\Throwable $e) {
            Log::error('Fallo al preparar recuperacion.', ['exception'=>get_class($e)]);
            throw new \RuntimeException('No se pudo preparar la recuperacion.');
        }
    }
}
