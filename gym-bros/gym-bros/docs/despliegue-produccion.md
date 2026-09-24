# Despliegue a produccion de la API

Lista para llevar la API a un servidor (Linux + Nginx + PHP-FPM + MySQL).
Los pagos con Mercado Pago quedan **desactivados** (`MP_ENABLED=false`) hasta
implementarlos: el checkout responde 503 y ningun flujo de pago se activa.

## 1. Requisitos
- PHP 8.2+ con `pdo_mysql`, `mbstring`, `openssl`, `fileinfo`, `gd`, `zip` y **OPcache activo**.
- MySQL 8, Composer 2, HTTPS (certificado valido).

## 2. Instalacion
```bash
composer install --no-dev --optimize-autoloader
cp .env.production.example .env    # completar los valores <...>
php artisan key:generate           # solo la primera vez
php artisan migrate --force        # solo agrega; revisar pendientes antes
php artisan storage:link
php artisan optimize               # cachea config, rutas, eventos y vistas
```
Con `config:cache` activo, `env()` solo se lee dentro de `config/`. Tras cambiar
`.env` hay que repetir `php artisan optimize`.

## 3. Variables que no pueden faltar
| Variable | Por que |
|---|---|
| `APP_DEBUG=false` | con `true` las respuestas de error exponen trazas y rutas |
| `APP_URL=https://...` | base de las URLs generadas por consola |
| `TRUSTED_PROXIES` | detras de un proxy TLS, sin esto todo responde 400 "Se requiere HTTPS" |
| `CORS_ALLOWED_ORIGINS` | origenes del panel; sin definir se permite `*` |
| `MAIL_*` | recuperacion de contrasena y altas de usuarios envian correo |

## 4. Procesos en segundo plano
Las colas usan la conexion `database`. Un worker (supervisor/systemd):
```bash
php artisan queue:work database --queue=recuperacion-password,solicitudes-demo,default --tries=5 --timeout=60 --sleep=3
```
Sin worker no salen los correos de recuperacion ni de activacion de cuentas.

Planificador (cron del usuario del sitio):
```cron
* * * * * cd /ruta/api && php artisan schedule:run >> /dev/null 2>&1
```
Ejecuta: vencimiento de suscripciones, desactivacion de usuarios con fecha
futura, recordatorios (09:00 America/Lima) y purga diaria de tokens vencidos.
Los scripts `scripts/*.vbs` son la alternativa para un servidor Windows.

### Imagenes publicas y la app en web
La app Flutter compilada para **web** dibuja las imagenes de `/storage/...`
(ejercicios, fotos, logos, banners) desde otro origen: el navegador exige la
cabecera `Access-Control-Allow-Origin` o muestra «Imagen no disponible». La app
nativa (APK) no la necesita. En desarrollo la pone `scripts/router-dev.php`; en
produccion debe ponerla el servidor web, por ejemplo en nginx:
```nginx
location /storage/ {
    add_header Access-Control-Allow-Origin "https://<dominio-de-la-app-web>";
}
```

## 5. Seguridad ya incorporada
- Todo lo privado exige token Sanctum (8 h) de una cuenta activa; logout revoca.
- Permisos por rol y empresa en `App\Support\Acceso`: cambiar un ID en la URL
  no da acceso a datos de otro usuario o gimnasio.
- Limites de peticiones: login 5/min por IP, API 240/min por usuario.
- En produccion la API rechaza HTTP plano.
- Mensajes de validacion en espanol (`lang/es`).

## 6. Pendientes conocidos
- **Laravel 11 (decision: se mantiene).** `composer audit` reporta avisos en
  Laravel 11.56 (CRLF en la regla `email`, URLs firmadas temporales) sin parche
  en la rama 11. El CRLF esta mitigado: todos los correos validan `not_regex` de
  caracteres de control. Las URLs firmadas solo se usan en el checkout, hoy
  desactivado: revisarlo al implementar Mercado Pago.
- **Mercado Pago**: implementar y probar en sandbox antes de `MP_ENABLED=true`.
- Estilo: `vendor/bin/pint --test` marca formato pendiente en archivos antiguos
  (sin efecto funcional).
