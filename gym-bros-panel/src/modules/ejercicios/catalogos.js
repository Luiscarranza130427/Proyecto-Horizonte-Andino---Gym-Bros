/**
 * Vocabulario cerrado del catálogo de ejercicios.
 *
 * Categoría, nivel y equipo son listas cerradas que aparecen en cuatro sitios:
 * los `permitidos` del listado, los `<select>` del formulario, el filtro y las
 * etiquetas legibles de la tabla y del detalle. Escribirlas cuatro veces
 * garantizaría que al añadir una categoría se olvidara alguna copia.
 *
 * El mock exporta estas mismas claves, pero un componente no puede importar de
 * `@/mocks` (los datos simulados no deben viajar al bundle), así que la parte
 * que la interfaz necesita —el valor y su etiqueta en español— vive aquí.
 */

export const CATEGORIAS = [
  { valor: 'pecho', etiqueta: 'Pecho' },
  { valor: 'espalda', etiqueta: 'Espalda' },
  { valor: 'piernas', etiqueta: 'Piernas' },
  { valor: 'hombros', etiqueta: 'Hombros' },
  { valor: 'brazos', etiqueta: 'Brazos' },
  { valor: 'core', etiqueta: 'Core' },
  { valor: 'cardio', etiqueta: 'Cardio' },
]

export const NIVELES = [
  { valor: 'principiante', etiqueta: 'Principiante' },
  { valor: 'intermedio', etiqueta: 'Intermedio' },
  { valor: 'avanzado', etiqueta: 'Avanzado' },
]

export const EQUIPOS = [
  { valor: 'ninguno', etiqueta: 'Sin equipo' },
  { valor: 'mancuernas', etiqueta: 'Mancuernas' },
  { valor: 'barra', etiqueta: 'Barra' },
  { valor: 'maquina', etiqueta: 'Máquina' },
  { valor: 'polea', etiqueta: 'Polea' },
  { valor: 'kettlebell', etiqueta: 'Kettlebell' },
]

/** Valores admitidos de un catálogo, para los `permitidos` y la validación. */
export function valoresDe(catalogo) {
  return catalogo.map((opcion) => opcion.valor)
}

/**
 * Etiqueta legible de un valor.
 *
 * El guion no es una defensa contra otro nombre de campo: el servicio garantiza
 * `categoria`, `nivel` y `equipo`, pero pueden llegar vacíos, y una celda vacía
 * en una tabla se lee como un fallo de la aplicación.
 */
export function etiquetaDe(catalogo, valor) {
  return catalogo.find((opcion) => opcion.valor === valor)?.etiqueta ?? '—'
}
