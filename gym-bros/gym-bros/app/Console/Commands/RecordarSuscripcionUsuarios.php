<?php

namespace App\Console\Commands;

use App\Models\Notificacion;
use App\Models\Usuario;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RecordarSuscripcionUsuarios extends Command
{
    protected $signature = 'usuarios:recordar-suscripcion {--simular : Cuenta sin guardar notificaciones}';
    protected $description = 'Recuerda diariamente membresias que vencen en 1 a 7 dias';

    public function handle(): int
    {
        $hoy = CarbonImmutable::today('America/Lima');
        $usuarios = Usuario::whereBetween('fin_suscripcion', [
            $hoy->addDay()->toDateString(), $hoy->addDays(7)->toDateString(),
        ]);
        $this->info('Fecha Peru: '.$hoy->toDateString().'. Usuarios: '.$usuarios->count());
        if ($this->option('simular')) {
            return self::SUCCESS;
        }
        $fallos = 0;
        $enviados = 0;
        $usuarios->select('id')->chunkById(100, function ($filas) use ($hoy, &$fallos, &$enviados) {
            foreach ($filas as $fila) {
                try {
                    DB::transaction(function () use ($fila, $hoy, &$enviados) {
                        // Serializes this user's reminder even when two runners overlap.
                        $usuario = Usuario::whereKey($fila->id)->lockForUpdate()->first();
                        if (! $usuario || ! $usuario->fin_suscripcion) {
                            return;
                        }
                        $fin = CarbonImmutable::parse($usuario->fin_suscripcion, 'America/Lima')->startOfDay();
                        $dias = (int) $hoy->diffInDays($fin, false);
                        if ($dias < 1 || $dias > 7) {
                            return;
                        }
                        $titulo = 'Recuerda renovar tu membresia';
                        $inicio = $hoy->setTimezone(config('app.timezone'))->toDateTimeString();
                        $limite = $hoy->addDay()->setTimezone(config('app.timezone'))->toDateTimeString();
                        $notificacion = Notificacion::where('id_usuarios', $usuario->id)
                            ->where('tipo', 'suscripcion')->where('titulo', $titulo)
                            ->where('fecha_envio', '>=', $inicio)->where('fecha_envio', '<', $limite)
                            ->lockForUpdate()->first();
                        if ($notificacion && $notificacion->datos !== null) {
                            return;
                        }
                        $mensaje = 'Tu membresia vence el '.$fin->toDateString().'. Faltan '.$dias.' '.($dias === 1 ? 'dia' : 'dias').'. Contacta a tu gimnasio para renovar.';
                        $notificacion ??= new Notificacion(['leida'=>false, 'enviada'=>false]);
                        $notificacion->fill([
                            'id_usuarios'=>$usuario->id, 'id_empresas'=>$usuario->id_empresas,
                            'tipo'=>'suscripcion', 'titulo'=>$titulo, 'mensaje'=>$mensaje,
                            'fecha_envio'=>CarbonImmutable::now(config('app.timezone'))->toDateTimeString(),
                            'enviada'=>true,
                            'datos'=>[
                                'dias_restantes'=>$dias,
                                'fecha_fin'=>$fin->toDateString(),
                                'imagen_fondo'=>'email/notificaciones-fondo.webp',
                                'url_renovacion'=>$this->whatsapp($usuario->empresa?->telefono),
                            ],
                        ]);
                        if (! $notificacion->save()) {
                            throw new \RuntimeException('No se pudo registrar el recordatorio.');
                        }
                        $enviados++;
                    });
                } catch (\Throwable $exception) {
                    report($exception);
                    $this->error('Usuario '.$fila->id.': error al procesar el recordatorio.');
                    $fallos++;
                }
            }
        });
        $this->info('Notificaciones publicadas en la app: '.$enviados.'. Fallos: '.$fallos.'.');

        return $fallos ? self::FAILURE : self::SUCCESS;
    }

    private function whatsapp(?string $telefono): ?string
    {
        $telefono = trim($telefono ?? '');
        if ($telefono === '' || ! preg_match('/^[+0-9 ()-]+$/', $telefono)) {
            return null;
        }
        $numero = preg_replace('/\D/', '', $telefono);
        if (str_starts_with($numero, '00')) {
            $numero = substr($numero, 2);
        }
        if (preg_match('/^9[0-9]{8}$/', $numero)) {
            $numero = '51'.$numero;
        }
        return preg_match('/^[1-9][0-9]{9,14}$/', $numero)
            ? 'https://wa.me/'.$numero.'?text='.rawurlencode('Hola, quiero renovar mi membresia en el gimnasio.')
            : null;
    }
}
