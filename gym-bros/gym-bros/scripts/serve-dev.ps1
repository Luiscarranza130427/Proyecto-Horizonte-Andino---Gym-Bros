# Servidor de desarrollo de la API accesible desde la red local (panel y movil).
#
# Por que no basta `php artisan serve`:
# - En Windows el servidor embebido de PHP atiende una peticion a la vez
#   (PHP_CLI_SERVER_WORKERS no tiene efecto sin fork).
# - La instalacion de Laragon no carga OPcache, asi que Laravel se compila en
#   cada peticion (~1 s). Con varias peticiones en paralelo del panel la cola
#   llegaba a 20-30 s y el navegador cortaba con "Network Error".
# Este script activa OPcache solo para este proceso (sin tocar php.ini) y deja
# cada peticion en ~0,15 s.
#
# Uso:  powershell -ExecutionPolicy Bypass -File scripts\serve-dev.ps1 [-Puerto 8000] [-Php ruta\php.exe]
param(
    [int]$Puerto = 8000,
    [string]$Host_ = '0.0.0.0',
    [string]$Php = 'C:\laragon\bin\php\php-8.4.21-Win32-vs17-x64\php.exe'
)

$raiz = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $raiz 'public')
$router = Join-Path $raiz 'vendor\laravel\framework\src\Illuminate\Foundation\resources\server.php'

Write-Host "API Gym Bros en http://${Host_}:${Puerto} (OPcache activo)"
& $Php -d zend_extension=opcache -d opcache.enable=1 -d opcache.enable_cli=1 `
    -d opcache.validate_timestamps=1 -d opcache.revalidate_freq=0 `
    -S "${Host_}:${Puerto}" $router
