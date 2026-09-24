# Crear una evaluacion fisica

```text
POST /api/usuarios/{id_usuario}/evaluaciones
```

Controlador: `EvaluacionFisicaController::store`.
Headers: `Accept: application/json` y `Content-Type: application/json`.
Body: objeto JSON con los campos siguientes. El usuario se toma de la ruta;
no es necesario enviar `id_usuarios` y el Body no puede cambiar la asociacion.

| Campo | Tipo y validacion |
| --- | --- |
| `nivel_experiencia` | `1a3meses`, `4a8meses`, `1ano`, `mas1ano`, `2anos`, `3anos_mas` o `3anosamas` |
| `actividad_diaria` | `sedentario`, `activo_ligero`, `moderadamente_activo` o `muy_activo` |
| `objetivo` | `perdida_peso`, `ganancia_muscular`, `resistencia`, `recomposicion`, `aumento_fuerza` o `salud` |
| `edad` | Entero positivo que quepa en la columna actual |
| `peso` | Numero positivo, hasta 9999.99 |
| `altura` | Numero positivo, hasta 999.99 |
| `porcentaje_grasa` | Numero entre 0 y 100 |
| `masa_muscular` | Numero entre 0 y 9999.99 |
| `cintura`, `pecho`, `brazo`, `muslo`, `cadera` | Numeros positivos, hasta 9999.99 |
| `dias_semana` | Entero de 2 a 6 |
| `eleccion_dias` | Opcional: arreglo de dias distintos cuya cantidad coincide con `dias_semana`, o null |
| `tiempo_sesion_min` | Entero de 1 a 180, en minutos |
| `restricciones` | Uno de los valores del enum actual de restricciones |
| `fecha_evaluacion` | Fecha `YYYY-MM-DD`, desde 1000-01-01 hasta la fecha actual |

Todos los campos son obligatorios salvo `eleccion_dias`. Las mediciones permiten como maximo dos decimales
para evitar redondeos silenciosos al guardar. Estos son limites de almacenamiento y validacion basica,
no una evaluacion clinica. Se conservan las unidades que utiliza el proyecto; el endpoint no hace conversiones.

Dias admitidos: `Lunes`, `Martes`, `Miercoles`, `Jueves`, `Viernes`, `Sabado`, `Domingo`.
No se acepta un dia aislado como texto en nuevas evaluaciones. Omitir `eleccion_dias` guarda null;
el generador usa entonces su calendario predeterminado cuando se solicita generar la rutina.

Restricciones admitidas: `sin-restricciones`, `manco`, `cojo`, `paralitico`, `movilidad-reducida`,
`amputacion-de-extremidad`, `silla-de-ruedas`, `uso-de-muletas`, `uso-de-baston`, `uso-de-andador`,
`limitacion-de-brazos`, `limitacion-de-piernas`, `problemas-de-equilibrio`, `problemas-de-coordinacion`,
`lesion-reciente`, `cirugia-reciente`, `dolor-musculoesqueletico`, `limitacion-cardiovascular`,
`limitacion-respiratoria`, `discapacidad-visual`, `discapacidad-auditiva`.
La columna admite una sola restriccion. Se conservan los identificadores actuales por compatibilidad.

## Respuestas

- **201**: `data` contiene `id`, `id_usuarios` y los campos de la nueva evaluacion.
- **422**: `message` y `errors` indican los campos invalidos. La validacion devuelve JSON incluso sin Accept.
- **404**: el usuario no existe o el parametro de ruta no es numerico.

Cada POST valido agrega una evaluacion, incluso si coincide la fecha. No actualiza ni elimina las anteriores
y no genera una rutina automaticamente. Las consultas de perfil y peso/grasa toman la fecha mas reciente;
cuando la fecha coincide, eligen el ID mayor. Una evaluacion historica no reemplaza una mas reciente.

Registrar restricciones esta permitido; generar rutinas para esas restricciones sigue sujeto a las reglas
del generador. Guardar una evaluacion no garantiza que cumpla todos los requisitos para generar rutinas.
Se mantiene el flujo local actual por ID; no se agrega autenticacion en este cambio.

## Pruebas

La suite cubre insercion e historial, consultas posteriores, usuario tomado de la ruta, campos no autorizados,
restricciones, dias opcionales, precision decimal, limites de columnas, fechas invalidas, campos faltantes,
usuarios inexistentes y respuestas JSON. Las pruebas automaticas usan SQLite en memoria con las migraciones
reales de evaluaciones. La prueba MySQL utiliza la copia aislada y revierte la insercion al terminar.
