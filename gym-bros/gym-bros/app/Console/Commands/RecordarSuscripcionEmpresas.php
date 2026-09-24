<?php

namespace App\Console\Commands;

use App\Models\Empresa;
use App\Models\Notificacion;
use App\Models\Usuario;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RecordarSuscripcionEmpresas extends Command
{
    protected $signature = 'empresas:recordar-suscripcion {--simular : Cuenta sin guardar notificaciones}';
    protected $description = 'Notifica a empresas y administradores vencimientos de suscripcion en 1 a 7 dias';

    public function handle(): int
    {
        $hoy = CarbonImmutable::today('America/Lima');
        $fallos = 0;
        $publicadas = 0;
        $candidatas = 0;
        Empresa::select('id')->chunkById(100, function ($empresas) use ($hoy, &$fallos, &$publicadas, &$candidatas) {
            foreach ($empresas as $fila) {
                try {
                    $cantidad = DB::transaction(function () use ($fila, $hoy, &$candidatas) {
                        // Serializes reminders and subscription edits for this company.
                        $empresa = Empresa::whereKey($fila->id)->lockForUpdate()->first();
                        if (! $empresa) {
                            return 0;
                        }
                        $suscripcion = $empresa->suscripciones()->where('estado','activa')
                            ->where('fecha_inicio','<=',$hoy->toDateString())
                            ->where('fecha_fin','>=',$hoy->toDateString())
                            ->orderByDesc('fecha_fin')->orderByDesc('id')->lockForUpdate()->first();
                        if (! $suscripcion) {
                            return 0;
                        }
                        $fin = CarbonImmutable::parse($suscripcion->fecha_fin,'America/Lima')->startOfDay();
                        $dias = (int) $hoy->diffInDays($fin,false);
                        if ($dias < 1 || $dias > 7) {
                            return 0;
                        }
                        $candidatas++;
                        if ($this->option('simular')) {
                            return 0;
                        }
                        $titulo = 'La suscripcion de tu empresa esta por vencer';
                        $inicio = $hoy->setTimezone(config('app.timezone'))->toDateTimeString();
                        $limite = $hoy->addDay()->setTimezone(config('app.timezone'))->toDateTimeString();
                        $cantidad = 0;
                        Usuario::where(function ($query) use ($empresa) {
                            $query->whereRaw('LOWER(tipo_usuario) = ?', ['administrador'])
                                ->orWhere(function ($query) use ($empresa) {
                                    $query->whereRaw('LOWER(tipo_usuario) = ?', ['empresa'])->where('id_empresas',$empresa->id);
                                });
                        })->select('id')->chunkById(100, function ($usuarios) use ($empresa, $suscripcion, $titulo, $inicio, $limite, $fin, $dias, &$cantidad) {
                            foreach ($usuarios as $usuario) {
                                $existe = Notificacion::where('id_empresas',$empresa->id)->where('id_usuarios',$usuario->id)
                                    ->where('tipo','suscripcion')->where('titulo',$titulo)
                                    ->where('fecha_envio','>=',$inicio)->where('fecha_envio','<',$limite)
                                    ->lockForUpdate()->first();
                                if ($existe) {
                                    continue;
                                }
                                $notificacion = new Notificacion([
                                    'id_empresas'=>$empresa->id,'id_usuarios'=>$usuario->id,
                                    'tipo'=>'suscripcion','titulo'=>$titulo,
                                    'mensaje'=>'La suscripcion de '.$empresa->nombre.' vence el '.$fin->toDateString().'. Faltan '.$dias.' '.($dias === 1 ? 'dia' : 'dias').'.',
                                    'fecha_envio'=>CarbonImmutable::now(config('app.timezone'))->toDateTimeString(),
                                    'enviada'=>true,'leida'=>false,
                                    'datos'=>[
                                        'evento'=>'suscripcion_empresa_por_vencer',
                                        'id_suscripcion'=>$suscripcion->id,'nombre_empresa'=>$empresa->nombre,
                                        'dias_restantes'=>$dias,'fecha_fin'=>$fin->toDateString(),
                                        'imagen_fondo'=>'email/notificaciones-fondo.webp','url_renovacion'=>null,
                                    ],
                                ]);
                                if (! $notificacion->save()) {
                                    throw new \RuntimeException('No se pudo guardar la notificacion.');
                                }
                                $cantidad++;
                            }
                        });
                        return $cantidad;
                    });
                    $publicadas += $cantidad;
                } catch (\Throwable $exception) {
                    report($exception);
                    $this->error('Empresa '.$fila->id.': no se pudieron publicar los recordatorios.');
                    $fallos++;
                }
            }
        });
        $this->info('Fecha Peru: '.$hoy->toDateString().'. Empresas por vencer: '.$candidatas.'. Notificaciones publicadas: '.$publicadas.'. Fallos: '.$fallos.'.');
        return $fallos ? self::FAILURE : self::SUCCESS;
    }
}
