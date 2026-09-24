/**
 * Regiones del Perú. `valor` es exactamente lo que acepta la API
 * (`UpdateEmpresaRequest`, sin tildes); `etiqueta` es lo que se muestra.
 *
 * Antes el valor llevaba tildes («Áncash», «Junín»...): la empresa se creaba
 * así y después la API rechazaba cualquier edición con 422 por región inválida.
 */
export const REGIONES_PERU = [
  { valor: 'Amazonas', etiqueta: 'Amazonas' },
  { valor: 'Ancash', etiqueta: 'Áncash' },
  { valor: 'Apurimac', etiqueta: 'Apurímac' },
  { valor: 'Arequipa', etiqueta: 'Arequipa' },
  { valor: 'Ayacucho', etiqueta: 'Ayacucho' },
  { valor: 'Cajamarca', etiqueta: 'Cajamarca' },
  { valor: 'Callao', etiqueta: 'Callao' },
  { valor: 'Cusco', etiqueta: 'Cusco' },
  { valor: 'Huancavelica', etiqueta: 'Huancavelica' },
  { valor: 'Huanuco', etiqueta: 'Huánuco' },
  { valor: 'Ica', etiqueta: 'Ica' },
  { valor: 'Junin', etiqueta: 'Junín' },
  { valor: 'La Libertad', etiqueta: 'La Libertad' },
  { valor: 'Lambayeque', etiqueta: 'Lambayeque' },
  { valor: 'Lima', etiqueta: 'Lima' },
  { valor: 'Loreto', etiqueta: 'Loreto' },
  { valor: 'Madre de Dios', etiqueta: 'Madre de Dios' },
  { valor: 'Moquegua', etiqueta: 'Moquegua' },
  { valor: 'Pasco', etiqueta: 'Pasco' },
  { valor: 'Piura', etiqueta: 'Piura' },
  { valor: 'Puno', etiqueta: 'Puno' },
  { valor: 'San Martin', etiqueta: 'San Martín' },
  { valor: 'Tacna', etiqueta: 'Tacna' },
  { valor: 'Tumbes', etiqueta: 'Tumbes' },
  { valor: 'Ucayali', etiqueta: 'Ucayali' },
]

/** Traduce una región guardada con o sin tildes al valor que acepta la API. */
export function valorRegion(region) {
  const plano = String(region ?? '')
    .trim()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
  if (!plano) return ''
  return REGIONES_PERU.find((opcion) => opcion.valor.toLowerCase() === plano)?.valor ?? region
}

/** Etiqueta con tildes para mostrar una región guardada. */
export function etiquetaRegion(region) {
  const valor = valorRegion(region)
  return REGIONES_PERU.find((opcion) => opcion.valor === valor)?.etiqueta ?? region ?? ''
}
