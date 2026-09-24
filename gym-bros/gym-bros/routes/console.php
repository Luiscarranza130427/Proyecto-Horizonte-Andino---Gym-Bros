<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('suscripciones:vencer')->daily()->withoutOverlapping(60)
    ->appendOutputTo(storage_path('logs/suscripciones-vencimiento.log'));

Schedule::command('usuarios:desactivar-fecha-futura')->daily()->withoutOverlapping(60)
    ->appendOutputTo(storage_path('logs/usuarios-fecha-futura.log'));

Schedule::command('usuarios:recordar-suscripcion')->dailyAt('09:00')->timezone('America/Lima')->withoutOverlapping(60)
    ->appendOutputTo(storage_path('logs/recordatorios-suscripcion.log'));

Schedule::command('empresas:recordar-suscripcion')->dailyAt('09:05')->timezone('America/Lima')->withoutOverlapping(60)
    ->appendOutputTo(storage_path('logs/recordatorios-empresas.log'));

Schedule::call(function () {
    if (! config('mercadopago.enabled')) { return; }
    \App\Models\OrdenCompra::where('estado','aprobado')->whereNull('correo_enviado_en')->select('id')->chunkById(100, function ($ordenes) {
        foreach ($ordenes as $orden) {
            \App\Jobs\EnviarConfirmacionCompra::dispatch($orden->id)->onConnection('database');
        }
    });
})->name('checkout-confirmaciones-pendientes')->hourly()->withoutOverlapping(60);
