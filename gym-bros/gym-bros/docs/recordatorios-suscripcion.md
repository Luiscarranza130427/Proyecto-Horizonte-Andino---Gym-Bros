# Recordatorios dentro de la app

Comando: `php artisan usuarios:recordar-suscripcion`.
Simulacion sin escrituras: `php artisan usuarios:recordar-suscripcion --simular`.
No usa correo, SMTP, WhatsApp automatico ni notificaciones push del dispositivo.

Todos los usuarios con fin_suscripcion entre manana y hoy + 7 dias reciben
una notificacion diaria, sin filtro por estado o rol. Fecha de negocio:
America/Lima. No cambia estados. Al renovar fuera del intervalo dejan de
generarse avisos; los anteriores conservan su informacion historica.

Se reutiliza notificaciones con tipo suscripcion, id_usuarios e id_empresas.
enviada=true significa publicada dentro de la app; leida=false hasta que el
usuario la lea. Los bloqueos del usuario y la consulta por dia y titulo impiden
duplicados entre ejecuciones del comando. Reejecutar no cambia la lectura ni
los datos del aviso publicado. No eliminar los registros para conservar esta
deduplicacion. Los fallos de escritura revierten la transaccion por usuario.

La migracion 2026_09_21_180000 agrega datos JSON nullable sin alterar los registros
existentes. Su down elimina solo esta columna y sus metadatos, no las
notificaciones originales. Los avisos antiguos siguen funcionando con datos=null.

Las respuestas existentes GET /api/notificaciones y GET /api/notificaciones/activas
incluyen datos con dias_restantes, fecha_fin, imagen_fondo, imagen_fondo_url y
url_renovacion. La app debe dibujar el diseno con estos valores y abrir
url_renovacion al pulsar Renovar ahora. Si es null, ocultar el boton y mostrar
contacto con el gimnasio. dias_restantes representa el dia en que se publico,
no un contador que modifica los avisos historicos.

El fondo sigue en public/storage/email/notificaciones-fondo.webp, aunque la
carpeta se llame email no se envia ningun correo. La URL usa el host de la API.
WhatsApp toma el telefono de la empresa del usuario al crear el aviso. Se
normalizan espacios, guiones y parentesis. Celulares peruanos de 9 digitos
reciben prefijo 51; otros paises deben incluir codigo internacional.

No se cambian permisos ni filtros de las rutas existentes: actualmente listan
notificaciones globales. Antes de exponerlas a usuarios finales hay que limitar
la consulta por usuario autenticado en backend, no solo filtrarla en Flutter.

Laravel Scheduler: 09:00 America/Lima todos los dias. Windows local usa la tarea
GYM-BROS Recordatorios Suscripcion con WScript oculto y ejecucion diaria;
requiere equipo encendido, sesion disponible y base de datos accesible. Usar
solo uno de los runners (Windows o Laravel Scheduler de produccion).
Log: storage/logs/recordatorios-suscripcion.log.

## Suscripciones de empresas

`php artisan empresas:recordar-suscripcion` publica avisos separados de las
membresias personales. `--simular` solo cuenta empresas candidatas.
Se elige la suscripcion activa actualmente vigente con mayor fecha_fin, como
en el estado de empresas. Si faltan entre 7 y 1 dias, reciben el aviso todos
los usuarios de tipo empresa vinculados a ella y todos los administradores,
sin filtro de estado. No se incluyen entrenadores ni clientes.
Se publica una vez por empresa, destinatario y dia (America/Lima); repetir la
tarea no modifica avisos leidos. Transaccion y bloqueo por empresa.

datos.evento = suscripcion_empresa_por_vencer permite distinguir estos avisos.
Incluye id_suscripcion, nombre_empresa, fecha_fin, dias_restantes y el mismo
fondo. datos.url_renovacion queda null para configurar la redireccion despues.
El frontend no debe abrir un enlace mientras sea null. No se agregan rutas,
migraciones, envios de correo ni cambios al estado de usuarios o empresas.

Scheduler: 09:05 America/Lima. Runner Windows alternativo:
GYM-BROS Recordatorios Empresas, script recordar-empresas-oculto.vbs.
Log: storage/logs/recordatorios-empresas.log. No activar ambos runners a la vez.
Las restricciones pendientes de las consultas globales tambien aplican aqui.
