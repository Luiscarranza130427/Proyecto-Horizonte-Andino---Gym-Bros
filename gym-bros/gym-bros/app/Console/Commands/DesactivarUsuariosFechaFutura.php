<?php

namespace App\Console\Commands;

use App\Models\Usuario;
use Illuminate\Console\Command;

class DesactivarUsuariosFechaFutura extends Command
{
    protected $signature = 'usuarios:desactivar-fecha-futura {--simular : Cuenta sin modificar registros}';
    protected $description = 'Desactiva usuarios con fin_suscripcion estrictamente posterior a hoy';

    public function handle(): int
    {
        $hoy = today()->toDateString();
        $usuarios = Usuario::where('estado', 1)->where('fin_suscripcion', '>', $hoy);
        $this->info('Fecha de corte: '.$hoy.' ('.config('app.timezone').').');
        // Future dates, not expired dates: this is the explicitly requested rule.
        if ($this->option('simular')) {
            $this->info('Usuarios que se desactivarian: '.$usuarios->count());

            return self::SUCCESS;
        }
        $cantidad = $usuarios->update(['estado' => 0]);
        $this->info('Usuarios desactivados: '.$cantidad);

        return self::SUCCESS;
    }
}
