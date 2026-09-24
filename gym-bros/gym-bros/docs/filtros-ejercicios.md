# Filtros de ejercicios

Ruta: GET /api/ejercicios. Todos los filtros son opcionales y se combinan con AND.

| Parametro | Valores / comportamiento |
| --- | --- |
| search | Contiene en nombre o descripcion, maximo 200 caracteres; % y _ son literales. |
| category | Tipo: fuerza, cardio, flexibilidad, equilibrio; o ID/descripcion exacta de grupo muscular principal o secundario. |
| level | principiante, intermedio, avanzado; admite diferencias de mayusculas. |
| equipment | Contiene en equipamiento, maximo 100 caracteres. |
| status | 1/0, true/false, active/inactive, activo/inactivo. |
| id_empresas | Empresa seleccionada; se mantienen los controles de autenticacion existentes. |
| page | Entero desde 1. |
| per_page | Entero de 1 a 100; por defecto 15 cuando se pide page sin per_page. |

Los filtros de texto vacios se ignoran. Para la opcion Todos, omitir el parametro
o enviar cadena vacia; no enviar las etiquetas Todos/all. Valores invalidos:
HTTP 422 con message y errors. Los resultados se ordenan por id ascendente.

Con empresa identificada, status filtra empresa_ejercicio.estado, no el estado
global. Inactivos incluye relaciones desactivadas y ejercicios sin relacion.
Sin empresa identificada, status filtra ejercicios.estado. El campo global no
se modifica ni se reemplaza por el estado de empresa.

Si se envia page o per_page, la respuesta contiene data, links y meta. Usar
meta.total, meta.current_page, meta.per_page y meta.last_page para el paginador.
Sin esos parametros, se conserva el listado completo dentro de data.

## Integracion Vue

- Reutilizar los parametros search, category, level, equipment, status,
  id_empresas, page y per_page.
- Volver a page=1 al cambiar filtros o empresa, antes de consultar.
- Para Categoria, preferir IDs de grupos musculares si ese es el contenido del
  selector. Si es tipo de ejercicio, enviar fuerza/cardio/flexibilidad/equilibrio.
- No filtrar ni paginar nuevamente data en el cliente: ya llega filtrado y paginado.
- Ignorar respuestas atrasadas o cancelar consultas anteriores al escribir.
- Leer el total de meta.total, no del numero de filas de la pagina.
- Mantener el token simulado solo en desarrollo local como hasta ahora.

## Verificacion

Pruebas en SQLite: filtros individuales, combinados, sin resultados, comodines
literales, grupos secundarios, estado por empresa, paginacion y entradas invalidas.
Comprobacion HTTP de solo lectura contra el servidor MySQL: busqueda, filtros
combinados, grupo muscular, activos/inactivos y validacion 422. Sin cambios de datos.
