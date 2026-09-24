<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AuditarAlturasAlimentacion extends Command
{
    protected $signature = 'alimentacion:auditar-alturas';
    protected $description = 'Informe de solo lectura: alturas pendientes de confirmar en centimetros';

    public function handle(): int
    {
        $tieneUnidad = Schema::hasColumn('evaluaciones_fisicas', 'altura_unidad');
        $campos = ['id', 'altura'];
        if ($tieneUnidad) {
            $campos[] = 'altura_unidad';
        }
        $filas = DB::table('evaluaciones_fisicas')->select($campos)->orderBy('id')->get()->map(function ($fila) use ($tieneUnidad) {
            $valor = (float) $fila->altura;
            $estado = $tieneUnidad && $fila->altura_unidad === 'cm' ? 'Unidad registrada: cm' : 'Confirmar unidad y valor original';
            $sugerencia = $valor >= 1.3 && $valor <= 2.2 ? 'Posible valor en metros; NO convertido'
                : ($valor >= 130 && $valor <= 220 ? 'Posible valor en cm; confirmar' : 'Valor fuera del alcance del generador');

            return [$fila->id, $fila->altura, $estado, $sugerencia];
        })->all();
        $this->table(['Evaluacion', 'Altura actual', 'Estado', 'Observacion'], $filas);
        $this->info('Solo lectura: no se actualizo ningun registro.');

        return self::SUCCESS;
    }
}
