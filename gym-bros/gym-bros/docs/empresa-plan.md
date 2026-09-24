# Plan al crear o editar una empresa

Rutas existentes, sin cambios:

```text
POST /api/empresas
PUT /api/empresas/{id_empresa}
```

Agregar opcionalmente id_planes al cuerpo existente. Se acepta un entero de
un plan existente, activo y con duracion_dias positiva. Omitirlo o enviar null
no modifica suscripciones. El POST conserva los campos obligatorios actuales,
incluida la posibilidad de enviar imagenes con multipart/form-data.

Ejemplo de PUT que solo asigna un plan:

```json
{"id_planes": 1}
```

## Comportamiento administrativo

- Asignacion inmediata, sin pasarela, sin crear pagos ni afirmar que se pago.
- fecha_inicio = hoy en la zona horaria de Laravel (actualmente UTC).
- fecha_fin = inicio + duracion_dias - 1. El ultimo dia esta incluido.
- Nueva suscripcion: estado activa, renovacion_automatica false.
- Si hay una unica suscripcion activa, vigente y del mismo plan, se devuelve
  esa suscripcion sin duplicarla ni extenderla. Para renovar ese mismo plan
  mediante esta opcion, su vigencia debe haber terminado.
- Al cambiar plan, las anteriores activas pasan a cancelada (o vencida si su
  fecha_fin ya paso), conservando sus IDs, fechas y pagos. Incluye activas con
  inicio futuro: esta operacion es reemplazo inmediato, no renovacion diferida.
- Los registros pendientes, suspendidos, cancelados y vencidos no se alteran.
- No cambia estados de usuarios ni reactiva automaticamente la empresa.
- Empresa y suscripcion se guardan en una transaccion; en edicion se bloquea
  la fila de la empresa para serializar solicitudes de esta misma operacion.
  Otros futuros escritores de suscripciones deben respetar el mismo bloqueo.
- Un fallo revierte empresa e historial; al crear, se eliminan archivos recien
  subidos. No se eliminan imagenes previas ni archivos de otras empresas.

## Respuesta y Vue

POST exitoso: 201. PUT exitoso: 200. Se conserva el perfil de empresa dentro de
data y, cuando se envia un plan no nulo, se agrega data.suscripcion:

```json
{
  "id": 1,
  "id_empresas": 1,
  "id_planes": 1,
  "fecha_inicio": "2026-09-16",
  "fecha_fin": "2026-10-15",
  "estado": "activa",
  "renovacion_automatica": false
}
```

Este bloque ilustra data.suscripcion, no reemplaza el resto de data. Los IDs y
fechas dependen de la operacion. Sin seleccion, no se agrega ese campo nuevo.
Vue debe enviar id_planes desde el selector y leer data.suscripcion tras guardar.
No enviar el ID del plan como id de empresa ni enviar fechas calculadas por Vue.
Mostrar errors.id_planes ante un 422. Los errores inesperados devuelven 500 con
message generico y los detalles quedan solo en el log. Empresa inexistente: 404.

No se agregaron middleware ni autorizacion nueva: estas rutas conservan la
autorizacion existente (FormRequest authorize=true). Antes de exponerlas en
produccion deben restringirse a administradores autenticados. Enviar id_planes
no demuestra un pago. No se implementa cobro, prorrateo ni devolucion.

## Archivos y pruebas

- EmpresaController.php, StoreEmpresaRequest.php, UpdateEmpresaRequest.php.
- EmpresaResource.php agrega solo la respuesta condicional.
- app/Services/Empresa/AsignarPlanEmpresaService.php.
- tests/Feature/EmpresaPlanTest.php: creacion, edicion, reintentos, fechas,
  entradas invalidas, aislamiento, imagenes y rollback.
- No hay migraciones ni se actualizaron registros existentes para instalarlo.

Las pruebas usan SQLite en memoria. No verifican concurrencia real en MySQL.
Antes del cambio ya fallaban dos pruebas antiguas que esperan excluir
fecha_registro del listado, mientras el recurso actual lo incluye. Se conserva
ese comportamiento y no se cambian pruebas ajenas para ocultar los fallos.
