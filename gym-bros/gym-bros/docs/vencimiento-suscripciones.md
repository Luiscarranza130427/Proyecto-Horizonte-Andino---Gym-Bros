# Vencimiento automatico de suscripciones

Comando disponible en la raiz del proyecto:

```text
php artisan suscripciones:vencer --simular
php artisan suscripciones:vencer
```

El primero informa cuantos registros cambiaria sin escribir. El segundo ejecuta
un UPDATE condicional: estado=activa y fecha_fin < hoy pasan a estado=vencida.
Solo cambia estado y updated_at. El ultimo dia de fecha_fin sigue incluido.
No cambia usuarios, empresas, fechas, planes, pagos ni renovacion_automatica.
No reactiva pendientes, vencidas, canceladas o suspendidas. No realiza cobros ni
crea renovaciones aunque renovacion_automatica=true. Repetirlo es idempotente.
Recupera todos los vencimientos atrasados, no solo los de ayer.

## Programacion

routes/console.php registra suscripciones:vencer diariamente a las 00:00 de la
zona horaria de Laravel. El proyecto esta configurado en UTC; 00:00 UTC corresponde
a las 19:00 del dia anterior en Lima. No se cambio APP_TIMEZONE para evitar
inconsistencias con los calculos de vigencia existentes.
Impide solapamientos y agrega la salida a storage/logs/suscripciones-vencimiento.log.
Los errores de base de datos hacen fallar el comando; no se ocultan como exito.

La tarea Windows "GYM-BROS Laravel Scheduler" ahora se ejecuta una vez al dia,
a las 19:00 de Lima (00:00 UTC), sin repeticion cada minuto. Llama directamente
a suscripciones:vencer mediante scripts/vencer-suscripciones-oculto.vbs.
WScript inicia PowerShell oculto, espera su resultado y propaga el codigo de
salida. La salida se agrega a storage/logs/suscripciones-vencimiento.log.
El lanzador tambien admite --simular; otros argumentos devuelven codigo 2.

Windows evita instancias simultaneas, limita la ejecucion a diez minutos,
recupera ejecuciones atrasadas y reintenta hasta tres veces cada quince minutos
si falla. Ejecutar el comando directamente permite recuperar fechas pasadas
sin depender del minuto exacto de schedule:run. No configurar ambos runners
simultaneamente para este despliegue.

La tarea local todavia requiere equipo encendido, sesion iniciada y MySQL
disponible. Windows denego el cambio a inicio de sesion S4U por falta de permisos.
No se guardaron contrasenas ni se elevaron privilegios. Para Windows produccion,
un administrador debe configurar una cuenta de servicio con ejecucion sin
sesion interactiva y asegurar que MySQL arranque como servicio. Revisar permisos
de archivos, logs y conexion de esa cuenta. Ajustar las rutas absolutas del
lanzador al desplegar. Esta configuracion local no equivale a un despliegue
completo de produccion.

Verificar programacion:
```text
php artisan schedule:list
```

En Linux, para ejecutar exclusivamente este proceso una vez al dia, configurar
el cron del servidor en UTC con:
```cron
0 0 * * * cd /ruta/al/proyecto && /usr/bin/php artisan suscripciones:vencer --no-interaction >> storage/logs/suscripciones-vencimiento.log 2>&1
```
Verificar rutas y zona horaria en el servidor. Cron requiere servidor encendido;
no recupera automaticamente un horario perdido. Como alternativa para todas
las tareas Laravel, schedule:run cada minuto es el funcionamiento habitual:
solo ejecuta cada tarea cuando le corresponde. No activar las dos opciones.

## Validacion del cambio a ejecucion diaria

- Cinco pruebas de vencimiento y 40 assertions correctas en SQLite aislado.
- Tarea verificada: intervalo diario, sin repeticion por minuto, lanzador oculto.
- Simulacion oculta: el error de MySQL no disponible queda en el log y devuelve 1.
- Argumento invalido: devuelve 2 sin ejecutar Artisan.
- No se modificaron registros de suscripciones durante estas comprobaciones.
- Pendiente de comprobar contra MySQL disponible; la conexion fue rechazada.

## Alcance y QA

No se agregaron middleware ni rutas HTTP. Esto actualiza el estado almacenado;
NO bloquea acceso por si solo. El control de identidad, empresa y vigencia queda
fuera de este cambio, segun lo solicitado.

- Cinco pruebas especificas, 40 assertions, correctas en el proyecto principal.
- QA completa previa: 263 pruebas correctas en la copia de validacion.
- MySQL: simulacion sin cambios, vencimiento correcto, ultimo dia vigente,
  otros estados intactos, repeticion idempotente y rollback de fixtures.
- Primera ejecucion real con respaldo JSON: 0 suscripciones vencidas.
  Empresas y usuarios sin cambios.
- Suite principal completa actual: 269 pruebas, 2 fallos ajenos a esta tarea.
  ActualizarEmpresaTest y EmpresaUsuariosCountTest esperan omitir fecha_registro,
  pero EmpresaResource actualmente lo incluye. No se altero ese codigo.

Archivos: app/Console/Commands/VencerSuscripciones.php, routes/console.php,
tests/Feature/VencerSuscripcionesTest.php y este documento. Sin migraciones.
