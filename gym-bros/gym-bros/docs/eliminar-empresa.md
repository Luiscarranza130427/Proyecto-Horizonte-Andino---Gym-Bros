# Eliminar empresa permanentemente

```text
DELETE /api/empresas/{id_empresa}
```

Cuerpo JSON obligatorio:
```json
{"confirmar_eliminacion": true}
```

Enviar Accept: application/json y Content-Type: application/json.
El ID de la ruta es la unica empresa objetivo; un ID enviado en el cuerpo no se usa.
HTTP 200 devuelve message y data con id_empresa y usuarios_eliminados.
HTTP 404: empresa inexistente (tambien si se repite el borrado).
HTTP 422: falta confirmacion. HTTP 409: relaciones cruzadas o restriccion de datos.
HTTP 500: fallo inesperado. Todos estos errores controlados son JSON sin trazas.

## Alcance irreversible

Elimina la empresa, TODOS sus usuarios de cualquier tipo/estado y datos dependientes:
evaluaciones, rutinas y sus ejercicios asignados, planes alimentarios, comidas y
alimentos asignados a comidas, preferencias, perfiles alimentarios, progresos,
sensaciones y uso del generador de rutinas. Tambien elimina suscripciones, pagos,
historial de cambios, notificaciones propias y vinculos empresa-ejercicio.
Las notificaciones globales sin destinatario ni empresa se conservan.

No elimina los catalogos compartidos de ejercicios, alimentos, grupos musculares,
planes SaaS o banners globales. No borra archivos de imagen porque pueden estar
compartidos; su limpieza no forma parte de esta operacion. No modifica el modelo
Laravel User ni sesiones de autenticacion de otra tabla.

El proceso usa una transaccion y bloquea empresa, usuarios y suscripciones objetivo.
Limpia primero las relaciones restrictivas, notificaciones y la tabla de uso sin FK;
las claves foraneas existentes ejecutan el resto de la cascada. No desactiva FK ni
modifica migraciones. Cualquier fallo revierte los borrados realizados en la base.
Referencias inconsistentes a pagos, usuarios, rutinas o evaluaciones de otra empresa
bloquean el borrado, en lugar de eliminar datos ajenos.

## Interfaz y seguridad

Vue debe mostrar una confirmacion que advierta que se eliminaran permanentemente
empresa, usuarios, historial y pagos. Solo enviar DELETE tras confirmar y actualizar
el listado despues de HTTP 200. No llamar DELETE al cargar una pagina ni mediante GET.

IMPORTANTE: confirmar_eliminacion evita solicitudes accidentales, NO autentica ni
autoriza. Se mantiene la situacion actual del backend sin middleware nuevo, segun
el alcance acordado. Esta ruta es destructiva y debe estar limitada al entorno de
pruebas; antes de exponerla agregar autenticacion y permiso exclusivo de administrador
del SaaS. No confundir la confirmacion JSON con proteccion frente a otros clientes.
Para recuperar datos eliminados se requiere un respaldo; no existe deshacer.

## Validacion y archivos

Pruebas SQLite: cascada, aislamiento, confirmacion, empresa vacia/ausente,
fallo final con rollback, restriccion inesperada y pago cruzado de otra empresa.
MySQL: copia independiente con las FK reales; borrado de las tres empresas de la
copia validado y revertido, incluidos catalogos y datos de otros usuarios conservados.
Ninguna empresa fue eliminada de la base principal durante la implementacion.

Archivos: DeleteEmpresaRequest.php, Services/Empresa/EliminarEmpresaService.php,
EmpresaController::destroy(), routes/api.php y tests/Feature/EliminarEmpresaTest.php.
No requiere migraciones. Se genero respaldo SQL antes de la prueba MySQL.
