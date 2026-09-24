# Editar empresa

```text
PUT /api/empresas/{id_empresa}
```

Edicion parcial: enviar JSON con solo los campos a modificar. Respuesta HTTP 200
con la empresa actualizada dentro de data (EmpresaResource). No requiere migraciones.

Campos editables: nombre, nombre_gerente, region, ruc, enlace_web, direccion,
telefono, correo, estado, fecha_registro, logo y horario_inicio/horario_fin
para lunes, martes, miercoles, jueves, viernes, sabado y domingo.

color_1, color_2, banner_1/2/3 y link_boton_1/2/3 no se actualizan aunque se
envien. id y campos desconocidos tampoco se actualizan. Los campos excluidos
siguen apareciendo en la respuesta con su valor anterior para conservar el recurso.
Peticion vacia o solo con campos excluidos/desconocidos: HTTP 422, errors.datos.

Campos obligatorios en la tabla admiten omision pero no null. Campos nullable
(region, ruc, enlace_web, direccion y horarios de fin de semana) admiten null.
telefono es texto de hasta 9 caracteres, correo valido hasta 150, fecha_registro
usa YYYY-MM-DD. region debe coincidir con el enum existente (ejemplo: Lima).
logo es la ruta de imagen como texto, no un archivo multipart.
Los horarios mantienen el almacenamiento decimal actual: numeros entre 0 y 24,
con hasta 2 decimales; no se admite HH:mm ni se convierte su representacion.

Validacion devuelve HTTP 422 con message y errors, incluso sin Accept.
ID de empresa inexistente con solicitud valida: HTTP 404 con message.
Una validacion fallida no modifica ningun campo.

Se mantienen las rutas anteriores de banners, creacion y listado, incluida la
omision de fecha_registro en el index. No se implementa autenticacion nueva:
esta ruta debe protegerse posteriormente con los middlewares de identidad y
permisos por empresa antes de exponerla fuera del entorno de pruebas.

Archivos: app/Http/Requests/UpdateEmpresaRequest.php,
app/Http/Controllers/EmpresaController.php, routes/api.php y
tests/Feature/ActualizarEmpresaTest.php.
