# Generador de rutinas, version 1

Motor deterministico en Laravel. Flutter y Vue solicitan la generacion y muestran el JSON.
Los parametros son una propuesta inicial de entrenamiento, pendiente de revision del entrenador;
las pruebas de software no certifican adecuacion clinica ni sustituyen esa revision.

## Estructura

- `app/Services/Rutina/AnalizadorEvaluacionService.php`: valida la ultima evaluacion y resuelve nivel y calendario.
- `app/Services/Rutina/DistribuidorMuscularService.php`: aplica la distribucion semanal y comprueba separacion entre grupos programados.
- `app/Services/Rutina/SelectorEjerciciosService.php`: consulta ejercicios disponibles, filtra y puntua.
- `app/Services/Rutina/GeneradorRutinaService.php`: coordina, calcula volumen/tiempo y guarda en una transaccion.
- `config/rutinas.php`: parametros y tablas de decision.
- `RutinaController::generar`: recibe el usuario, llama al servicio y devuelve `GeneracionRutinaResource`.

## Relaciones y compatibilidad

Se conservan los nombres y rutas existentes. Se agrega un endpoint.
Usuario tiene evaluaciones y rutinas. Empresa y ejercicios usan `empresa_ejercicio`.
Ejercicio y grupos usan `ejercicios_grupo_muscular`. Rutina tiene detalles en `ejercicios_rutina`.
Tambien se incluyen las relaciones N:M de rutinas/ejercicios para consultas.

La nueva migracion agrega `id_grupos_musculares` a la tabla intermedia y completa sus registros
con el musculo principal ya registrado en `ejercicios.id_grupos_musculares`.
No infiere musculos secundarios, elimina duplicados ni reemplaza el campo principal.
Cuando no hay registros en la intermedia, el selector sigue usando el musculo principal.
El campo nuevo admite null para que consultas SQL antiguas que solo insertan `id_ejercicios` sigan funcionando.
Las nuevas relaciones completas deben incluir ambos IDs. Los duplicados existentes no duplican ejercicios candidatos.

`eleccion_dias` pasa de enum a texto que admite arreglos JSON o null. Los valores historicos
como `Lunes` se conservan. El Resource del listado mantiene su representacion historica;
los nuevos arreglos se devuelven como arreglos. Un dia aislado no se completa adivinando los demas.
El enum de experiencia agrega las variantes utilizadas en los Requests sin eliminar valores antiguos.
El nombre historico `isquitiobiales` se normaliza en memoria; no se renombra en la BD.
La relacion singular heredada `Ejercicio::empresa()` queda intacta por compatibilidad;
el generador utiliza exclusivamente la relacion correcta `empresas()`.

## Reglas iniciales

- Ultima evaluacion: fecha descendente y luego ID descendente. Una evaluacion futura produce 422.
- Usuario y empresa activos; empresa tomada del usuario, nunca del cuerpo de la solicitud.
- Ejercicio activo, habilitado en la empresa, grupo principal activo y nivel permitido.
- Principiante: 1a3meses / 4a8meses. Intermedio: 1ano / mas1ano. Avanzado: 2anos / 3anosamas / 3anos_mas.
- `4a8anos` es ambiguo: se conserva en BD, pero se rechaza al generar hasta corregir la evaluacion.
- Solo se generan rutinas para `sin-restricciones`. Una restriccion vacia, desconocida o sin reglas produce 422.
- Rango inicial: adultos de 18 a 100 anos, 2 a 6 dias y hasta 180 minutos. No equivale a aptitud medica.
- Peso y altura deben ser positivos. No se deducen cargas ni prioridades musculares de medidas corporales.
- Actividad diaria se valida y se conserva como contexto; no modifica volumen con umbrales no definidos.
- Los objetivos difieren en repeticiones, descansos, series adicionales y cardio opcional.
- Los bloques musculares seleccionan ejercicios de fuerza; perdida_peso y resistencia agregan cardio si existe y cabe.
- No se estima gasto calorico: el catalogo no tiene datos para calcularlo.
- Sensaciones quedan fuera de esta version; no se consultan ni modifican.

| Dias | Distribucion | Calendario si eleccion_dias es null |
| --- | --- | --- |
| 2 | Completo / completo | Lunes, jueves |
| 3 | Completo / completo / completo | Lunes, miercoles, viernes |
| 4 | Superior / inferior / superior / inferior | Lunes, martes, jueves, viernes |
| 5 | Empuje / tiron / inferior / superior / inferior | Lunes, martes, miercoles, viernes, sabado |
| 6 | Empuje / tiron / inferior, repetido | Lunes a sabado |

Los dias proporcionados se ordenan de lunes a domingo. Deben ser distintos y coincidir con dias_semana.
Se comprueba una separacion de dos dias para grupos programados, incluyendo el cambio de semana.
Esta comprobacion no modela toda la fatiga de musculos secundarios ni horarios exactos.

## Puntuacion

Primero se aplican todos los filtros obligatorios. Ningun puntaje puede saltarselos.
Se suman 30 puntos por nivel exacto (15 por inferior), 30 por grupo coincidente,
8 por ser el musculo principal y 20 por tipo compatible con el objetivo.
Se restan 6 por cada uso del ejercicio en dias anteriores de la misma rutina.
El desempate usa ID ascendente; no hay azar. Se excluyen ejercicios ya elegidos en esa sesion.
La compatibilidad de objetivo es basica, basada en `tipo`; no se inventan etiquetas de hipertrofia o potencia.

## Tiempo, fechas y persistencia

Estimacion de un ejercicio por repeticiones:

`series * repeticiones * 4 + (series - 1) * descanso_segundos`

La sesion incluye 300 segundos de calentamiento y 45 entre ejercicios. Son estimaciones, no tiempos reales garantizados.
Si no cabe, se reducen series hasta el minimo configurado; luego se omite el cardio opcional.
Si aun no cabe, se devuelve 422. No se reducen descansos ni se omiten grupos obligatorios.

- `tiempo_segundos`: duracion estimada total del ejercicio, incluidos descansos entre series.
- Cardio: una serie, cero repeticiones, duracion en segundos y cero descanso.
- `duracion_estimada`: minutos de la sesion mas larga, redondeados hacia arriba.
- `dia`: numero de sesion (1..N), no numero de dia calendario. El JSON incluye `dia_semana`.
- `peso`: 0 como marcador de pendiente, explicado en notas; no es una prescripcion de carga.
- Inicio: siguiente ocurrencia del primer dia del calendario, incluida la fecha actual si coincide.
- Vigencia: cuatro semanas configurables; fin inclusivo.
- Una nueva rutina no elimina ni desactiva las anteriores. Repetir POST crea otra rutina.
- Cabecera y detalles se guardan atomicamente. Un fallo revierte ambos.

## Peticion y respuesta

```http
POST /api/rutinas/generar/1
Accept: application/json
Content-Type: application/json

{}
```

El cuerpo no sustituye la evaluacion ni la empresa. La informacion se obtiene de la BD.
Ejemplo completo, generado en una copia de MySQL con el catalogo existente:
`docs/rutina-generada.ejemplo.json`. Sus IDs y fechas son ilustrativos; la transaccion de prueba se revirtio.

Respuesta 201: `data` contiene los campos de rutina, `ejercicios`, `sesiones` y `advertencias`.
404: usuario inexistente o parametro de ruta no numerico. 422: evaluacion, disponibilidad o tiempo incompatibles.

```json
{
  "message": "La cantidad de dias elegidos debe coincidir con dias_semana.",
  "errors": {
    "eleccion_dias": ["La cantidad de dias elegidos debe coincidir con dias_semana."]
  }
}
```

Las dos evaluaciones locales revisadas conservaban un unico dia. Hay que completar sus dias reales
antes de generar; alternativamente null solicita explicitamente el calendario predeterminado.
No se modificaron esas elecciones de los usuarios para hacer pasar una prueba.

La ruta conserva el esquema local sin tokens solicitado previamente. El ID no acredita identidad.
Antes de exponerla fuera del entorno de pruebas debe incorporarse autenticacion y autorizacion por usuario/empresa.

## Consultar una sesion guardada

```http
GET /api/usuarios/1/rutinas/3/sesiones/2
Accept: application/json
```

Consulta la sesion 2 de la rutina 3 perteneciente al usuario 1. No necesita Body.
El parametro `dia` es el numero de sesion, no el dia de la semana.
Se utiliza el ID de rutina obtenido en `data.id` al generar; no se elige automaticamente otra rutina.

Respuesta 200: `data.id_usuarios`, `data.id_rutinas`, `data.dia`, `data.dias_semana`,
`data.duracion_estimada`, `data.objetivo` y `data.ejercicios`.
Los tres campos de contexto provienen de la rutina guardada, aunque la evaluacion cambie despues.
`duracion_estimada` esta en minutos y corresponde a la sesion mas larga de la rutina,
no a su vigencia en semanas ni necesariamente a la duracion del dia consultado.
Cada ejercicio conserva su orden, series, repeticiones, peso, descansos, tiempo y notas;
tambien incluye los datos del ejercicio y su grupo muscular principal.

Devuelve 404 si la rutina no pertenece al usuario, si no existe la rutina/sesion
o si esa sesion no tiene ejercicios guardados. La consulta no crea ni modifica registros.
Verificar la pertenencia no sustituye la futura autenticacion con tokens.

## Verificacion

1. Pruebas originales antes de editar: 2 aprobadas.
2. Nuevas pruebas escritas antes de implementar, dentro de una copia aislada.
3. Matriz de los 6 objetivos x 5 cantidades de dias, datos invalidos y limites temporales.
4. Filtros por empresa/estado/nivel, relacion muscular secundaria, cardio, determinismo y recuperacion.
5. Fallo simulado durante el segundo detalle: no quedan cabecera ni detalles.
6. Migracion en copia MySQL 8.0.30: preservacion de columnas originales en 30 tablas y 34 relaciones completadas.
7. Generacion real sobre el catalogo de esa copia, serializacion JSON y rollback de datos de prueba.
8. Suite completa y rutas verificadas antes y despues de trasladar los cambios al proyecto.

Validacion previa al traslado: 62 pruebas, 1512 aserciones, sintaxis correcta en los 21 archivos PHP
afectados; las 30 rutas originales permanecen y se agrega una ruta POST.

Ejecutar la suite con el PHP de Laragon, habilitando SQLite solo para ese proceso:

```powershell
& 'C:\laragon\bin\php\php-8.3.33-Win32-vs16-x64\php.exe' -d extension=pdo_sqlite -d extension=sqlite3 vendor\phpunit\phpunit\phpunit
```

Las nuevas pruebas fuerzan SQLite en memoria antes de crear tablas; nunca migran ni vacian la BD configurada en `.env`.
No usar `migrate:fresh` en la base de trabajo. El rollback de la migracion se detiene si los dias o niveles nuevos
no caben en los enums anteriores; requiere resolver esos datos sin perdida antes de retroceder.
