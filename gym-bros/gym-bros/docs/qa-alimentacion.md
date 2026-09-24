# QA del generador de alimentacion

## Antes de implementar

El proyecto principal es C:/laragon/www/gym-bros. Esta copia QA parte del codigo
actual, no de la copia antigua de rutinas. La base real solo se consulta.
Las pruebas utilizan SQLite :memory:; se verificara tambien el DDL en MySQL
en una base exclusiva de QA. No se ejecuta migrate:fresh.

## Matriz de validacion

- Regresion: ejecutar toda la suite existente antes y despues del cambio.
- Esquema: migraciones incrementales conservan filas antiguas y dejan metadatos
  desconocidos como null/no verificados; comprobar FK y rollback del DDL en QA.
- Altura: nuevas entradas en centimetros, rechazar metros/valores fuera de rango;
  no alterar registros historicos ni deducir su unidad automaticamente.
- Perfil: revision explicita, adultos dentro del alcance, embarazo/lactancia o
  plan clinico bloqueados; fecha de nacimiento y edad de evaluacion coherentes.
- Datos: nutrientes negativos, fuente ausente, unidades desconocidas,
  conversion sin equivalencia, pasos y limites invalidos, alergeno desconocido.
- Seleccion: rechazos y restricciones prevalecen sobre preferencias; datos de
  alergenos desconocidos se excluyen; catalogo insuficiente devuelve 422.
- Generacion: varios dias, cantidad/horarios de comidas, objetivos por dia,
  cantidades redondeadas dentro de limites, totales recalculados y tolerancias.
- Aislamiento: ultima evaluacion por fecha e ID del usuario solicitado, consulta
  de un plan ajeno devuelve 404; no se acepta reasignacion desde el body.
- Persistencia: repetir crea otro plan sin modificar el anterior; error despues
  de insertar alimentos revierte plan/comidas/detalles completos.
- HTTP: errores JSON aun sin Accept, validacion 422, recursos ausentes 404,
  generador deshabilitado 503 hasta revision de las reglas.

## Decisiones provisionales, no aprobacion nutricional

Se implementara una version configurable para adultos con revision profesional
registrada. Los factores, repartos y tolerancias son parametros iniciales de QA,
no prescripciones. La habilitacion global estara desactivada por defecto.
La cantidad de comidas, horarios y duracion seran explicitos en cada solicitud.
Las preferencias historicas no se reinterpretan: se agrega tipo nullable.
Los alimentos historicos no se certifican ni completan automaticamente.

## Resultados

### Activacion autorizada

- Se repitieron las 215 pruebas originales del modulo antes de desplegar.
- Suite actual: 216 pruebas, 2572 assertions; incluye activacion tecnica sin
  simular revision profesional y rechazo de perfiles incompletos.
- Se repitio la integracion MySQL en la copia aislada.
- Respaldo nuevo: respaldo-activacion-alimentacion-20260912.sql y manifiesto JSON,
  fuera del proyecto, antes de aplicar exclusivamente las dos migraciones reales.
- API habilitada con alimentacion.habilitado=true. No hay aprobacion global pendiente.
- Smoke tests reales: listado de alimentos, planes, restricciones y peso/grasa 200.
- Generacion para el usuario existente sin perfil: 422 de datos incompletos, no 503.
- Todos los valores de las columnas originales se conservaron. No se insertaron
  alimentos ficticios, perfiles clinicos inventados ni planes de prueba reales.
- Las verificaciones clinicas y la procedencia de alimentos no se sustituyen por
  la autorizacion del despliegue.

### Historial anterior a la activacion

- Suite original: 154 pruebas, 2117 assertions, todas correctas. El primer intento
  detecto pdo_sqlite deshabilitado en PHP CLI; se cargo solo para los procesos de QA
  con -d extension=pdo_sqlite -d extension=sqlite3, sin modificar Laragon.
- Suite ampliada: 215 pruebas, 2565 assertions, todas correctas.
- MySQL 8.0.30: migraciones incrementales, down/up y generacion con FK, DECIMAL,
  JSON y serializacion verificadas en gym_bros_qa_alimentacion_20260912.
- Los valores de columnas originales se conservaron tras las migraciones de QA.
- Los alimentos/perfil/evaluacion sinteticos y planes de integracion se insertaron
  en una transaccion de QA y se revirtieron al terminar.
- Huellas del esquema y datos de las 32 tablas reales: sin cambios.
- Sintaxis PHP comprobada en todos los archivos cambiados.
- Se agregaron verificaciones de nutrientes mixtos, pasos fraccionarios, altura
  antes/despues de migrar, auditoria de solo lectura y duracion maxima de 14 dias.
- Pruebas nutricionales usan fixtures sinteticos. Pasar QA no valida clinicamente
  los coeficientes ni convierte el catalogo real en informacion verificada.

Script reproducible de MySQL y respaldo fuera del proyecto:
C:/Users/pimpi/Documents/ChatGPT/GYM-BROS 2/qa-alimentacion-mysql.php
El modo validar-qa comprueba el nombre exacto de la base aislada antes de migrar.
El modo verificar-real solo compara huellas. No repetir clonar sobre un respaldo
existente. No se importan fixtures ni se migran tablas reales.
