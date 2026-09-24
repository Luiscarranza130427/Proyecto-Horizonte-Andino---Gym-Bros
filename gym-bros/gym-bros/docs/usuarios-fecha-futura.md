# Desactivacion por fecha futura

Regla confirmada: usuarios.estado=1 y fin_suscripcion > hoy pasan a estado=0.
No es vencimiento: desactiva fechas futuras. Fechas iguales, anteriores y NULL
no cambian. No reactiva usuarios. Solo actualiza estado y updated_at.
Hoy se calcula en la zona Laravel, actualmente UTC.

```text
php artisan usuarios:desactivar-fecha-futura --simular
php artisan usuarios:desactivar-fecha-futura
```

La simulacion no escribe. Un UPDATE condicional hace los reintentos idempotentes.
Tarea Windows: GYM-BROS Usuarios Fecha Futura, diariamente 19:00 Lima (00:00 UTC).
Usa scripts/desactivar-usuarios-oculto.vbs sin ventanas y registra la salida en
storage/logs/usuarios-fecha-futura.log. Requiere equipo encendido, sesion iniciada
y MySQL disponible, igual que la tarea existente. Recupera ejecuciones atrasadas
y reintenta errores tres veces cada quince minutos.

Tambien registrada en routes/console.php para despliegues con Laravel Scheduler.
No ejecutar simultaneamente el runner general y la tarea directa en el mismo
despliegue. La tarea Windows previa de suscripciones no se modifico.

Validacion: siete pruebas (incluyendo vencimiento de suscripciones), 53 assertions.
Simulacion local: tres candidatos; lanzador oculto retorno 0. No se ejecutaron
cambios reales durante la instalacion; se aplicaran en la ejecucion programada.
No hay migraciones, rutas HTTP ni middleware nuevos.
