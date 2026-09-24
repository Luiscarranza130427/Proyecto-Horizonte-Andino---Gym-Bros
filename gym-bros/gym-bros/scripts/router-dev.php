<?php

/*
 * Router del servidor de desarrollo (`serve-dev.ps1`).
 *
 * Igual que el de Laravel, salvo por los archivos públicos de `storage/`
 * (fotos, logos, banners, imágenes de ejercicios): se sirven con
 * `Access-Control-Allow-Origin: *`. La app Flutter compilada para web corre en
 * otro puerto y el navegador no le deja dibujar una imagen de otro origen sin
 * esa cabecera: se veía «Imagen no disponible». La app nativa no lo necesita.
 */

$publico = getcwd();
$ruta = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/');
$archivo = realpath($publico.$ruta);
$storage = realpath($publico.DIRECTORY_SEPARATOR.'storage');

if (str_starts_with($ruta, '/storage/') && $archivo !== false && $storage !== false
    && str_starts_with($archivo, $storage.DIRECTORY_SEPARATOR) && is_file($archivo)) {
    header('Access-Control-Allow-Origin: *');
    header('Content-Type: '.(mime_content_type($archivo) ?: 'application/octet-stream'));
    header('Content-Length: '.filesize($archivo));
    header('Cache-Control: public, max-age=3600');
    readfile($archivo);

    return true;
}

return require __DIR__.'/../vendor/laravel/framework/src/Illuminate/Foundation/resources/server.php';
