# Estado de suscripcion en empresas

```text
GET /api/empresas
```

Cada empresa incluye estado_suscripcion para la etiqueta de la web:

- Activo: al menos una suscripcion activa y vigente termina dentro de 7 dias o mas.
- Por Vencer: la suscripcion activa y vigente termina entre hoy y dentro de 6 dias.
- Inactivo: no tiene suscripciones activas vigentes (incluye vencidas, pendientes,
  suspendidas, canceladas, activas que ya finalizaron y las que aun no empiezan).

Vigencia: estado=activa, fecha_inicio <= hoy y fecha_fin >= hoy.
Si varias cumplen, se utiliza la fecha_fin mas lejana; una renovacion futura que
todavia no empezo no se considera vigente. Los dias se comparan como fechas de
calendario en la zona del proyecto (UTC), no como bloques de 24 horas desde ahora.
El ultimo dia esta incluido. Exactamente 7 dias no es Por Vencer.

Frontend: cambiar la etiqueta que antes dependia de estado por estado_suscripcion.
estado conserva su valor administrativo original; no se convierte en texto ni se
modifica en la base. Una empresa bloqueada manualmente puede tener una suscripcion
vigente, y ambos campos representan condiciones diferentes.

No se escribe Por Vencer en suscripciones.estado (no existe en su enum).
El listado calcula la etiqueta al consultar sin depender de que el Scheduler
haya marcado vencida una suscripcion atrasada. No se modifican otras rutas,
usuarios, suscripciones, bloqueo de acceso ni tareas programadas.

La respuesta sigue dentro de data; cantidad_usuarios y los demas campos se
conservan. La consulta combina conteo y agregado de fecha en una sola consulta,
sin cargar historiales completos ni ejecutar una consulta por empresa.

Cambios: Empresa::suscripciones(), EmpresaController::index(), EmpresaResource
y pruebas de listado. No requiere migraciones. La etiqueta solo se agrega cuando
el recurso recibe el agregado cargado por el index.
