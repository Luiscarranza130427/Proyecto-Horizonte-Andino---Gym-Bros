<?php

namespace App\Support;

/**
 * Normaliza las rutas de archivos del disco `public` guardadas en la base.
 *
 * Los datos historicos contienen rutas absolutas de Windows
 * (`C:\laragon\www\gym-bros\storage\app\public\usuario\x.jpg`), rutas con la
 * carpeta interna (`\storage\app\public\...`), rutas con prefijo `/storage/`
 * y rutas relativas del disco (`usuario/x.jpg`). Todas terminan en la misma
 * ruta relativa y en una URL publica `/storage/...` sin duplicar el prefijo.
 */
final class RutaPublica
{
    public static function relativa(?string $ruta): ?string
    {
        $ruta = trim((string) $ruta);
        if ($ruta === '' || self::esUrlAbsoluta($ruta)) {
            return null;
        }
        $ruta = str_replace('\\', '/', $ruta);
        // Todo lo que haya antes de la carpeta publica interna es ruta del servidor.
        if (preg_match('#(?:^|/)storage/app/public/(.+)$#i', $ruta, $m)) {
            $ruta = $m[1];
        } elseif (preg_match('#^/?(?:public/)?storage/(.+)$#i', $ruta, $m)) {
            $ruta = $m[1];
        } elseif (preg_match('#^[a-z]:/#i', $ruta)) {
            return null; // Ruta absoluta ajena al disco publico: no se expone.
        }
        $ruta = ltrim(preg_replace('#/+#', '/', $ruta), '/');
        if ($ruta === '' || in_array('..', explode('/', $ruta), true)) {
            return null;
        }

        return $ruta;
    }

    public static function url(?string $ruta): ?string
    {
        $ruta = trim((string) $ruta);
        if (self::esUrlAbsoluta($ruta)) {
            return $ruta;
        }
        $relativa = self::relativa($ruta);
        if ($relativa === null) {
            return null;
        }
        $base = app()->runningInConsole() && ! app()->runningUnitTests()
            ? rtrim((string) config('app.url'), '/')
            : request()->getSchemeAndHttpHost();

        return $base.'/storage/'.implode('/', array_map('rawurlencode', explode('/', $relativa)));
    }

    private static function esUrlAbsoluta(string $ruta): bool
    {
        return (bool) preg_match('#^https?://#i', $ruta);
    }
}
