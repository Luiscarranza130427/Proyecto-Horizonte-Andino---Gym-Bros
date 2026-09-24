# Resumen web

```text
GET /api/usuarios/{id_usuario}/resumen-web
```

Respuesta HTTP 200: objeto data con id_usuario, tipo_usuario, id_empresa,
alcance (global/empresa), cantidad_usuarios, cantidad_ejercicios y plan_empresa.
cantidad_empresas solo existe para Administrador: se omite para los otros roles.
Los roles se leen desde usuarios, ignorando parametros de rol o empresa del cliente.
Se aceptan los valores existentes Administrador, Empresa y Entrenador, sin distinguir
mayusculas. Usuario u otro rol y solicitantes inactivos reciben 403; ID ausente, 404.
Empresa/Entrenador sin empresa existente recibe 422 con message y errors.

## Conteos

- Administrador: todos los usuarios, empresas y ejercicios, incluidos inactivos.
- Empresa/Entrenador: todos los usuarios vinculados a su empresa, incluidos
  inactivos y todos los roles. Ejercicios con estado=true y vinculacion activa
  en empresa_ejercicio para esa empresa, sin duplicados ni datos de otras empresas.
- Este endpoint devuelve cantidades, no listados completos de usuarios/ejercicios.

## Plan de la empresa

Se utiliza la empresa del usuario de la ruta, tambien para Administrador. Si este
no tiene empresa, plan_empresa es null; no se elige arbitrariamente otra empresa.
Suscripcion vigente: estado=activa, fecha_inicio <= hoy y fecha_fin >= hoy.
Si existen varias, prevalece fecha_inicio mas reciente y luego id mas alto.
Sin suscripcion vigente devuelve null. Un plan retirado del catalogo (activo=false)
no elimina la suscripcion vigente que ya tenia contratada la empresa.

plan_empresa incluye los campos de PlanResource (id, nombre, descripcion,
precio_original, precio_inicial, limite_usuarios, activo, contenido, enlace_whatsapp)
y duracion_dias, id_suscripcion, fecha_inicio, fecha_fin, estado_suscripcion.
Es el plan SaaS de planes, NO un plan alimentario. Se corrige la referencia
App/Models/Plan.php a planes; no se modifica el modelo PlanAlimentacion.

## Seguridad y despliegue

Solo lectura; no requiere migraciones ni modifica registros. El controlador
implementa alcance por rol, NO autenticacion: mientras se permita elegir cualquier
id_usuario en la ruta, un cliente puede suplantar ese contexto. Antes de produccion
el middleware debe vincularlo a la identidad autenticada y comprobar autorizacion.
No exponer esta ruta a clientes no confiables mientras tanto.

Archivos: ResumenWebController.php, routes/api.php, Models/Plan.php y
tests/Feature/ResumenWebTest.php. Pruebas SQLite aisladas cubren roles, aislamiento,
inactivos, cero ejercicios, empresa ausente, fechas y estados de suscripcion,
desempate de suscripciones y relacion/catalogo de planes SaaS.
