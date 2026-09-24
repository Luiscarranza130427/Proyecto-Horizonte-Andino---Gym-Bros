/**
 * Vocabulario cerrado de alimentación.
 *
 * Los valores son los ENUM LITERALES de `docs/MODELO_DE_DATOS.md`; las etiquetas
 * son lo que se lee en pantalla. Aparecen en los `permitidos` de los listados,
 * en los `<select>` de filtros y formularios y en las celdas de las fichas:
 * escribirlos cuatro veces garantizaría que al tocar uno se olvidara alguna copia.
 *
 * El mock exporta las mismas claves, pero un componente no puede importar de
 * `@/mocks` —los datos simulados no deben viajar al bundle—, así que la parte
 * que la interfaz necesita vive aquí.
 */

/** `alimentos.tipo`. Sin tilde en los valores: son los del esquema. */
export const TIPOS_ALIMENTO = [
  { valor: 'proteina', etiqueta: 'Proteína' },
  { valor: 'carbohidrato', etiqueta: 'Carbohidrato' },
  { valor: 'grasa', etiqueta: 'Grasa' },
  { valor: 'fruta', etiqueta: 'Fruta' },
  { valor: 'verdura', etiqueta: 'Verdura' },
  { valor: 'lacteo', etiqueta: 'Lácteo' },
  { valor: 'cereal', etiqueta: 'Cereal' },
  { valor: 'legumbre', etiqueta: 'Legumbre' },
  { valor: 'bebida', etiqueta: 'Bebida' },
  { valor: 'otro', etiqueta: 'Otro' },
]

/**
 * `comidas.tipo_comida`, en el orden natural del día.
 *
 * El orden importa: es el que ordena el horario cuando dos comidas comparten
 * `hora_sugerida`, y el que se ofrece en el desplegable.
 */
export const TIPOS_COMIDA = [
  { valor: 'desayuno', etiqueta: 'Desayuno' },
  { valor: 'media_manana', etiqueta: 'Media mañana' },
  { valor: 'almuerzo', etiqueta: 'Almuerzo' },
  { valor: 'media_tarde', etiqueta: 'Media tarde' },
  { valor: 'cena', etiqueta: 'Cena' },
  { valor: 'snack', etiqueta: 'Snack' },
  { valor: 'otro', etiqueta: 'Otro' },
]

/** `comida_alimentos.unidad`. */
export const UNIDADES = [
  { valor: 'gramos', etiqueta: 'g', nombre: 'gramos' },
  { valor: 'mililitros', etiqueta: 'ml', nombre: 'mililitros' },
  { valor: 'unidad', etiqueta: 'ud', nombre: 'unidades' },
]

/**
 * `planes_alimentacion.activo`, traducido a las dos situaciones que se filtran.
 *
 * En el esquema es un booleano; aquí son dos valores con nombre porque un
 * `<select>` con «true/false» no se lee, y porque el filtro viaja por la URL.
 */
export const SITUACIONES_PLAN = [
  { valor: 'activo', etiqueta: 'Activos' },
  { valor: 'inactivo', etiqueta: 'Finalizados' },
]

/** Valores admitidos de un catálogo, para los `permitidos` y la validación. */
export function valoresDe(catalogo) {
  return catalogo.map((opcion) => opcion.valor)
}

/**
 * Etiqueta legible de un valor.
 *
 * El guion no es una defensa contra otro nombre de campo: el servicio garantiza
 * el campo, pero puede llegar vacío, y una celda vacía se lee como un fallo de
 * la aplicación en lugar de como un dato que falta.
 */
export function etiquetaDe(catalogo, valor) {
  return catalogo.find((opcion) => opcion.valor === valor)?.etiqueta ?? '—'
}

/** Posición de un tipo de comida en el día, para ordenar el horario. */
export function ordenDeComida(tipoComida) {
  const indice = TIPOS_COMIDA.findIndex((opcion) => opcion.valor === tipoComida)
  return indice === -1 ? TIPOS_COMIDA.length : indice
}
