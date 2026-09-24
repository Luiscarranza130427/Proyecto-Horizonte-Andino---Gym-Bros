<?php

require __DIR__.'/../../vendor/autoload.php';
$app = require __DIR__.'/../../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

if (! $app->environment('local') || DB::connection()->getDriverName() !== 'mysql') {
    throw new RuntimeException('Solo QA local MySQL.');
}
$original = config('database.default');
$database = 'gym_bros_checkout_qa_'.bin2hex(random_bytes(6));
if (! preg_match('/^gym_bros_checkout_qa_[a-f0-9]{12}$/', $database)) {
    throw new RuntimeException('Nombre QA no valido.');
}
$conexion = config('database.connections.'.$original);
$conexion['database'] = $database;
$conexion['url'] = null;
DB::connection($original)->statement('CREATE DATABASE `'.$database.'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
try {
    config(['database.connections.checkout_qa' => $conexion, 'database.default' => 'checkout_qa']);
    if (DB::connection()->getDatabaseName() !== $database) {
        throw new RuntimeException('Conexion QA incorrecta.');
    }
    foreach (['2026_08_21_224135_create_empresas.php', '2026_08_21_224236_create_usuarios.php', '2026_08_21_224524_create_planes.php',
        '2026_08_21_224533_create_suscripciones.php', '2026_08_21_224540_create_pagos.php', '2026_09_22_195900_create_personal_access_tokens.php'] as $file) {
        (require database_path('migrations/'.$file))->up();
    }
    $migration = require database_path('migrations/2026_09_22_200000_prepare_checkout.php');
    $migration->up();
    if (! Schema::hasTable('ordenes_compra') || ! Schema::hasColumn('usuarios', 'correo_normalizado')) {
        throw new RuntimeException('Falta esquema.');
    }
    $migration->down();
    if (Schema::hasTable('ordenes_compra')) {
        throw new RuntimeException('Rollback incompleto.');
    }
    $migration->up();
    echo "MySQL aislado: up/down/up correctos. Base principal sin cambios.\n";
} finally {
    DB::purge('checkout_qa');
    config(['database.default' => $original]);
    DB::connection($original)->statement('DROP DATABASE `'.$database.'`');
}
