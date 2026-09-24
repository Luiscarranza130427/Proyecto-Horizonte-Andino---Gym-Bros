<?php

namespace App\Console\Commands;

use App\Models\Suscripcion;
use Illuminate\Console\Command;

class VencerSuscripciones extends Command
{
    protected $signature = 'suscripciones:vencer {--simular : Muestra la cantidad sin modificar registros}';
    protected $description = 'Marca como vencidas las suscripciones activas cuya fecha_fin ya paso';

    public function handle(): int
    {
        $hoy = today()->toDateString();
        $suscripciones = Suscripcion::where('estado', 'activa')->where('fecha_fin', '<', $hoy);
        $this->info('Fecha de corte: '.$hoy.' ('.config('app.timezone').').');

        if ($this->option('simular')) {
            $this->info('Suscripciones que vencerian: '.$suscripciones->count());

            return self::SUCCESS;
        }

        // One conditional UPDATE: reruns are harmless and other states stay intact.
        $cantidad = $suscripciones->update(['estado' => 'vencida']);
        $this->info('Suscripciones vencidas: '.$cantidad);

        return self::SUCCESS;
    }
}
