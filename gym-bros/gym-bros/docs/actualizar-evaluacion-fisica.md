# Actualizar la ultima evaluacion fisica

```text
PUT /api/usuarios/{id_usuario}/evaluaciones/ultima
```

Controlador: `EvaluacionFisicaController::update`.
Headers: `Accept: application/json` y `Content-Type: application/json`.
Body JSON: enviar solamente los campos que se desean actualizar.

Se selecciona la evaluacion con mayor `fecha_evaluacion` del usuario de la ruta;
si hay varias en esa fecha, se elige la de mayor ID. No se elige solamente por fecha de insercion.
No se crea una nueva evaluacion ni se actualizan otras evaluaciones o rutinas.

Campos editables: `nivel_experiencia`, `actividad_diaria`, `objetivo`, `edad`, `peso`, `altura`,
`porcentaje_grasa`, `masa_muscular`, `cintura`, `pecho`, `brazo`, `muslo`, `cadera`, `dias_semana`,
`eleccion_dias`, `tiempo_sesion_min`, `restricciones` y `fecha_evaluacion`.
Los tipos, limites y valores permitidos son los mismos que en `crear-evaluacion-fisica.md`.

Los campos omitidos conservan sus valores. Solo `eleccion_dias` admite null.
`id`, `id_usuarios`, `created_at` y otros campos ajenos a la evaluacion no se actualizan desde el Body.
Una solicitud vacia o con solo campos no editables devuelve 422.

Si se modifica `dias_semana` o `eleccion_dias`, se comprueba la cantidad de dias usando el resultado
de combinar los campos enviados con los valores guardados. Si no coincide, no se guarda ningun cambio.
Se pueden enviar ambos campos juntos o utilizar `eleccion_dias: null` para dejar el calendario sin especificar.
Editar solo una medicion no obliga a reescribir un calendario historico.

La seleccion y actualizacion se realizan dentro de una transaccion con bloqueo de filas.
Si se cambia `fecha_evaluacion`, se actualiza el registro seleccionado originalmente;
la siguiente consulta de ultima evaluacion puede seleccionar otro registro segun la nueva fecha.

Respuestas:

- **200**: `data` contiene la evaluacion actualizada, incluido su `id` original e `id_usuarios`.
- **404**: usuario o evaluacion inexistente, o parametro de ruta no numerico.
- **422**: campos invalidos, Body sin campos editables o dias inconsistentes; incluye `message` y `errors`.

El ID de usuario mantiene el esquema local actual; no sustituye la futura autenticacion con tokens.

Pruebas: actualizacion parcial, seleccion por fecha e ID, aislamiento entre usuarios, conservacion del historial,
validacion de campos y precision, dias parciales/null, Body vacio, fecha editable, ausencia de registros,
rollback ante error posterior al guardado y verificacion de PUT en la copia aislada de MySQL.
