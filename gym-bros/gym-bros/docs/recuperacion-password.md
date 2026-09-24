# Recuperacion de contrasena: Vue, Flutter y Next.js

Independiente de Mercado Pago. Reutiliza password_reset_tokens (email, token,
created_at), que ya existia: no hay migraciones nuevas ni cambios a usuarios reales.
Broker Laravel usuarios, modelo Usuario, correo normalizado y password_hash.
No crea ni modifica empresas, roles, estados, compras o suscripciones.

## Contrato

POST /api/auth/forgot-password
Accept: application/json
Content-Type: application/json

```json
{"correo":"usuario@empresa.com"}
```

200, exista o no la cuenta, incluso inactiva o duplicada:
```json
{"message":"Si existe una cuenta con ese correo, recibirás las instrucciones para recuperar tu contraseña."}
```

POST /api/auth/reset-password
```json
{"correo":"usuario@empresa.com","token":"64 caracteres hexadecimales del enlace","password":"NuevaClaveSegura123!","password_confirmation":"NuevaClaveSegura123!"}
```

200:
```json
{"message":"Contraseña actualizada correctamente. Inicia sesión nuevamente."}
```

422: message y errors por campo (correo, token, password).
429: message y cabeceras de reintento. Cinco intentos por IP en diez minutos
por ruta. Forgot limita adicionalmente cada correo a un intento por minuto;
ese limite responde igualmente 200. 503: mensaje generico, sin excepciones.
Correo obligatorio valido maximo 255. Password minimo 12, letras y numeros,
maximo 255 y confirmacion coincidente. No requieren Bearer token.

## Enlace y seguridad

https://novawavedev.com/restablecer-contrasena#correo=...&token=...

Se usa fragmento, NO query: el navegador no lo envia al servidor Next.js ni
en Referer. Leer con URLSearchParams(window.location.hash.slice(1)), guardar
solo en memoria y quitar el fragmento con history.replaceState. No registrar
URL, correo, token ni passwords en consola, analitica, sessionStorage o logs.
Sin scripts externos/analitica en esta pantalla. Referrer-Policy: no-referrer.

PASSWORD_RESET_URL permite configurar exclusivamente en Laravel otra pagina
HTTPS confiable. Default: https://novawavedev.com/restablecer-contrasena.
No se aceptan dominios o destinatarios del cliente. SMTP procede del .env actual.

La API encola sin consultar existencia de cuenta, evitando diferencias por
esa condicion. El worker ignora correos desconocidos/duplicados y procesa
inactivos sin activarlos. Token generado con Laravel, hash en DB, 60 minutos,
un uso. Nueva generacion autorizada invalida el anterior; intervalo 60 segundos.
La sustitucion sucede al procesar el trabajo. Un correo viejo pendiente no se
envia si su token fue reemplazado, consumido o vencio.

Los dos jobs implementan ShouldBeEncrypted: jobs y failed_jobs conservan el
payload cifrado con APP_KEY. No rotar/perder APP_KEY sin plan para la cola.
Excepciones SMTP se sustituyen por mensajes genericos sin excepcion anterior;
logs solo contienen clase del error, no contenido SMTP ni datos sensibles.
Reintentos cinco veces. Una caida tras aceptar SMTP puede duplicar un correo;
no duplica la capacidad de usar el token. No existe garantia SMTP exactamente una vez.

Reset bloquea la cuenta y valida/cambia hash/revoca todos los tokens Sanctum/
consume token en una transaccion. Login bloquea la misma cuenta antes de emitir
un token para no emitir una sesion con clave antigua durante un reset concurrente.

## Operacion

```shell
php artisan queue:work database --queue=recuperacion-password --tries=5 --timeout=60 --sleep=3
```

La cola database debe usar la misma conexion que los usuarios. Cache persistente
para rate limiting. Se inicio worker local oculto, no una tarea de autoarranque:
tras reiniciar Windows debe iniciarse de nuevo. Produccion necesita supervisor.
APP_ENV=production requiere HTTPS; configurar proxies confiables si hay TLS
terminado en proxy. No habilitar captura de bodies de estas rutas en APM/proxies.
No se enviaron correos reales de prueba. Validar SMTP real requiere autorizacion.
La pagina de Next.js debe implementarse/publicarse: no se modificaron frontends.

## Archivos

- app/Http/Controllers/PasswordRecoveryController.php
- app/Http/Requests/RecuperarPasswordRequest.php
- app/Http/Requests/RestablecerPasswordRequest.php
- app/Services/Auth/PasswordRecoveryService.php
- app/Jobs/ProcesarRecuperacionPassword.php
- app/Jobs/EnviarRecuperacionPassword.php
- app/Mail/RecuperacionPassword.php
- resources/views/emails/recuperacion-password.blade.php
- app/Models/Usuario.php: correo para recuperacion.
- config/auth.php: broker y URL confiable.
- app/Providers/AppServiceProvider.php: limitador por IP.
- routes/api.php: rutas publicas independientes.
- app/Http/Middleware/ApiSesion.php: HTTPS en produccion.
- app/Http/Controllers/AuthController.php: emision serializada con reset.
- tests/Feature/PasswordRecoveryTest.php

## Prompt Vue

Agrega Olvide mi contrasena en el login existente, conservando la estructura.
Solicita correo y envia POST /api/auth/forgot-password con JSON {correo}.
Muestra el message del 200 igual para todos los correos. Muestra errors de 422,
respeta Retry-After en 429 y permite reintentar ante 503. Deshabilita doble envio.
No simules recuperacion ni muestres existencia de cuenta. No registres datos
sensibles. Explica que el correo abre una pagina web para definir nueva clave.
Despues el usuario vuelve al login. Ante 401 por sesion revocada, limpia sesion.

## Prompt Flutter

Agrega Olvide mi contrasena en el login existente. Solicita correo y envia
POST /api/auth/forgot-password con JSON {correo} y Accept application/json.
Muestra el mensaje generico del backend. Maneja 422 por campo, 429 y 503, con
boton deshabilitado mientras envia. No guardar/loguear correo o tokens de reset.
El enlace se abre en la web Next.js: no hace falta implementar deep links.
Tras restablecer, el usuario inicia sesion en la app con la nueva clave.
Ante 401 de una sesion revocada, elimina el token del almacenamiento seguro y
regresa al login sin bucles de reintento. No modificar el checkout.

## Prompt Next.js

Implementa /restablecer-contrasena con un componente cliente. Lee correo y token
desde window.location.hash usando URLSearchParams; capturalos una sola vez,
conserva en memoria y elimina fragmento con history.replaceState. No volver a
borrar el estado capturado al repetir efectos en React Strict Mode. No usar
query/searchParams de servidor ni servicios externos para procesar el enlace.
Si falta alguno, mostrar enlace invalido y opcion de solicitar otro.
Formulario password/password_confirmation, minimo 12 con letras y numeros.
Enviar POST /api/auth/reset-password a la API configurada, JSON con los cuatro
campos. Usar solo un destino API confiable, nunca una URL proveniente del enlace.
200: mostrar message y opciones de volver al panel o app, sin login automatico.
422: errors por campo, incluido token invalido/vencido/usado. 429: esperar segun
Retry-After; 503: permitir reintento. No persistir token/clave en almacenamiento.
Sin analitica, scripts de terceros, logs de URL/body ni telemetria del formulario.
Usar HTTPS, Referrer-Policy no-referrer y no-store. Si se recarga tras retirar
fragmento, indicar que debe volver a abrir el enlace del correo.
