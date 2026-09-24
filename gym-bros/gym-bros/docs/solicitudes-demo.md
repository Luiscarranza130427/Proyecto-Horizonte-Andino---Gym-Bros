# Solicitudes de demostracion

POST /api/solicitudes-demo recibe JSON {"correo":"cliente@empresa.com"}.
Correo obligatorio, valido, maximo 150 caracteres. Limite: cinco intentos por IP
en diez minutos (incluye intentos invalidos). No requiere checkout ni token.
No confiar en X-Forwarded-For arbitrario: configurar proxies confiables al desplegar.

201: {"data":{"id":123,"estado":"pendiente","mensaje":"Solicitud registrada correctamente."}}
422: message y errors.correo. 429: mensaje y headers de reintento.
503: error generico si no se pueden guardar solicitud y trabajo de cola.

La transaccion guarda solicitudes_demo y el trabajo en jobs en la misma conexion.
El destinatario fijo es info@novawavedev.com. No admite destinatario del cliente.
Mailable con Blade escapado; SMTP exclusivamente desde config/mail.php y .env.
La cola se llama solicitudes-demo. El worker reintenta cinco veces y registra
solo ID y clase del error, nunca el mensaje SMTP ni sus credenciales.
El estado pendiente representa seguimiento comercial, no entrega de correo.
La entrega SMTP no garantiza exactamente una vez ante una caida tras aceptacion.

## Operacion

```shell
php artisan queue:work database --queue=solicitudes-demo --tries=5 --timeout=60 --sleep=3
```

Worker local iniciado oculto durante implementacion. No se instala tarea del
sistema: tras reiniciar Windows debe volver a iniciarse. En produccion mantener
este comando con el supervisor del servidor. Configurar cache persistente para
rate limiting, DB_QUEUE_CONNECTION igual a la conexion principal y SMTP real.
Revisar failed_jobs y usar queue:retry para reintentar tras corregir el fallo.
No se envio correo real de prueba ni se insertaron solicitudes ficticias locales.

Migracion aplicada: 2026_09_23_000000_create_solicitudes_demo.php.
Su down elimina la tabla y sus registros: respaldar antes de revertir.
No se aplicaron migraciones de Mercado Pago.

Pruebas: tests/Feature/SolicitudDemoTest.php, SQLite aislado y Mail fake.
