# Alimentacion por seleccion de alimentos

Contrato vigente 2026-09-12. Sustituye las instrucciones anteriores de alergias
e intolerancias: el usuario solicito retirar ese subsistema y sus tres tablas.

## Rutas conservadas

```text
GET /api/alimentos
GET /api/usuarios/{id_usuario}/perfil-alimentario
PUT /api/usuarios/{id_usuario}/perfil-alimentario
POST /api/planesalimentacion/generar/{id_usuario}
```

PUT crea o actualiza el perfil del usuario de la ruta en una transaccion.
GET y PUT devuelven HTTP 200 con el mismo contrato dentro de data.
GET sin perfil devuelve 404; Flutter puede crear el perfil mediante PUT.

## Flutter

- Listar GET /api/alimentos: solo devuelve alimentos con activo=true.
- Todos los alimentos anteriores quedan activos por defecto.
- Sin preferencia previa: mostrar marcado. Con preferido: marcado.
- Con rechazado: mostrar desmarcado al volver a editar.
- Enviar JSON con preferencias: [{id_alimentos: ID, tipo: preferido/rechazado}].
- Enviar todo el grid; admite el catalogo completo (probado con 265 alimentos).
- Las preferencias omitidas conservan su estado. [] no borra rechazos previos.
- No se aceptan IDs inexistentes o repetidos, ni tipos distintos.
- El preferido puede usarse, no es obligatorio. El rechazado nunca es candidato.
- Un alimento inactivo queda fuera incluso si estaba marcado como preferido.
- Si el catalogo permitido no basta, generacion devuelve 422 sin guardar plan parcial.
- Los planes historicos conservan sus alimentos; editar preferencias no los regenera.

Siguen siendo obligatorios sexo_calculo, embarazo, lactancia,
requiere_plan_clinico, apto_plan_general y el array preferencias.
Con masculino, embarazo y lactancia deben ser false.
revision_profesional y revisado_en son opcionales/nullable y no bloquean generacion.
Omitirlos o enviar null preserva sus valores historicos; no se inventan fechas.
Las validaciones de evaluacion fisica y los indicadores clinicos no cambiaron.

Usar Accept: application/json y Content-Type: application/json.

## Restricciones retiradas

Se eliminan restricciones_alimentarias, alimento_restriccion y
usuario_restriccion_alimentaria, sus relaciones y las rutas GET/POST
/api/restriccionesalimentarias. No se convierten antecedentes en preferencias.
El respaldo completo previo conserva esos datos para recuperacion manual.

El API ya NO detecta alergias, ingredientes ni intolerancias automaticamente.
Las exclusiones se realizan exclusivamente por ID de alimento rechazado.
Por compatibilidad, GET/PUT mantienen restricciones: [].
Los arrays antiguos alergias, intolerancias y restricciones (nutricion) se pueden
omitir o enviar vacios. Con elementos devuelven 422, nunca se guardan silenciosamente.
El campo historico alimentos.restricciones_verificadas se conserva, es opcional
al actualizar nutricion y ya no tiene efecto en la seleccion. No se borra fuera
del alcance solicitado.

## Respuestas exactas

Capturadas en MySQL con fixtures revertidas, no son IDs para usar en usuarios reales:

- [Cuerpo PUT](perfil-flutter-put-request.json)
- [Respuesta PUT HTTP 200 completa](perfil-flutter-put-response.json)
- [Respuesta GET HTTP 200 completa](perfil-flutter-get-response.json)

Errores: 422 con message/errors, 401 sin identidad, 403 sin permiso, 404 inexistente.
El modulo devuelve JSON sin HTML ni trazas incluso con depuracion activada.

## Autorizacion

El proyecto aun no tiene login activo para estas rutas. Se conserva el acceso
anonimo SOLO en local/testing sin Authorization y con
ALIMENTACION_PERMITIR_SIN_SESION_LOCAL=true. No exponerlo en redes no confiables.
Fuera de local/testing se exige identidad autenticada. Un token no autenticado
devuelve 401. Un Usuario autenticado accede a su ID; otros accesos necesitan el
Gate gestionar-alimentacion. User pertenece a otra tabla y su mismo ID numerico
no otorga propiedad. No se implemento login ni permisos ficticios. El catalogo
conserva su acceso anterior. Antes de produccion debe conectarse el guard real.

## Migraciones

- 2026_09_12_120000_make_alimentacion_review_optional.php: columnas de revision nullable.
- 2026_09_12_130000_use_food_preferences_only.php: agrega alimentos.activo y elimina
  las tres tablas en orden de dependencias. No altera preferencias ni planes.

Las migraciones antiguas se conservan como historial. Una instalacion nueva las
ejecuta y luego retira las tablas; no deben borrarse archivos ya ejecutados.
La eliminacion no admite rollback automatico: se requiere el respaldo previo.
La revision no puede volver a NOT NULL si ya existen valores null.

## QA

Antes de editar el proyecto principal:
- Regresion nueva reproducida: el esquema anterior conservaba las tres tablas.
- Suite completa: 232 pruebas, 2736 assertions, sin errores.
- Creacion/edicion sin revision, checkboxes, IDs invalidos/repetidos, aislamiento.
- Catalogo activo, preferencias por usuario, catalogo insuficiente y rollback.
- MySQL: migraciones y GET/PUT 200, planes de 7 dias con 3, 4 y 5 comidas.
- Ningun alimento rechazado/inactivo en los planes; fixtures MySQL revertidas.
- Respaldo completo antes de retirar tablas. Comparacion de las filas originales
  de las tablas conservadas antes y despues del cambio.

## Archivos de implementacion

- app/Http/Controllers/AlimentacionController.php
- app/Http/Controllers/AlimentoController.php
- app/Http/Requests/GuardarPerfilAlimentarioRequest.php
- app/Http/Requests/ActualizarNutricionAlimentoRequest.php
- app/Http/Resources/AlimentoResource.php
- app/Http/Middleware/AutorizarUsuarioAlimentacion.php
- app/Http/Responses/ErrorAlimentacionResponse.php
- app/Models/Alimento.php
- app/Services/Alimentacion/SelectorAlimentosService.php
- app/Services/Alimentacion/CalculadorObjetivosService.php
- app/Services/Alimentacion/GeneradorPlanAlimentacionService.php
- config/alimentacion.php, bootstrap/app.php, routes/api.php
- tests/Feature/GeneradorAlimentacionTest.php
- Las dos migraciones indicadas, documentacion y SQL ficticio actualizado.

Retirados: app/Models/RestriccionAlimentaria.php y
app/Http/Requests/StoreRestriccionAlimentariaRequest.php.
