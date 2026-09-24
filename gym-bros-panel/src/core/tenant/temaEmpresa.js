/**
 * Traduce los dos colores de marca de una empresa a los tokens `--gb-*` del
 * panel, con el mismo reparto que la app móvil:
 *
 * - `color_1` («Color de fondo») tiñe las capas de fondo.
 * - `color_2` («Color de texto») es el acento: botones, menú activo, enlaces,
 *   foco… todo lo que hoy es el rojo de Gym Bros (`--gb-red`).
 *
 * Una empresa puede elegir cualquier par de colores, así que nada se aplica
 * tal cual: el fondo sólo se tiñe hasta donde el texto sigue siendo legible y
 * el acento se aclara si no destaca sobre el fondo. Son los mismos mínimos de
 * WCAG 2.1 AA que documenta `_variables.css`.
 */

const HEX = /^#([0-9a-f]{6})$/i

/** Capas de fondo del tema por defecto (ver `_variables.css`). */
const CAPAS = {
  '--gb-surface-lowest': '#0e0e0e',
  '--gb-bg': '#131313',
  '--gb-surface': '#1c1b1b',
  '--gb-surface-high': '#2a2a2a',
  '--gb-surface-highest': '#353534',
  '--gb-border': '#333333',
}

const TEXTO = '#e5e2e1'
const TEXTO_SECUNDARIO = '#c6c6c6'
const BLANCO = [255, 255, 255]
const NEGRO = [0, 0, 0]

/** Tokens que este módulo puede escribir; `removerTema` limpia exactamente estos. */
export const VARIABLES_TEMA = [
  ...Object.keys(CAPAS),
  '--gb-red',
  '--gb-red-hover',
  '--gb-red-rgb',
  '--gb-on-red',
  '--gb-red-text',
  '--gb-link-hover',
  '--gb-focus',
]

export function hexARgb(valor) {
  const coincidencia = HEX.exec(String(valor ?? '').trim())
  if (!coincidencia) return null
  const numero = Number.parseInt(coincidencia[1], 16)
  return [(numero >> 16) & 255, (numero >> 8) & 255, numero & 255]
}

export function rgbAHex(rgb) {
  return `#${rgb.map((canal) => Math.round(canal).toString(16).padStart(2, '0')).join('')}`
}

function luminancia(rgb) {
  const [r, g, b] = rgb.map((canal) => {
    const c = canal / 255
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
  })
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

export function contraste(a, b) {
  const [claro, oscuro] = [luminancia(a), luminancia(b)].sort((x, y) => y - x)
  return (claro + 0.05) / (oscuro + 0.05)
}

/** Mezcla `origen` hacia `destino` en la proporción indicada (0 = origen). */
function mezclar(origen, destino, proporcion) {
  return origen.map((canal, i) => canal + (destino[i] - canal) * proporcion)
}

/** Aclara `color` hacia el blanco lo justo para alcanzar `minimo` sobre `fondo`. */
function aclararHasta(color, fondo, minimo) {
  for (let paso = 0; paso <= 20; paso += 1) {
    const candidato = mezclar(color, BLANCO, paso / 20)
    if (contraste(candidato, fondo) >= minimo) return candidato
  }
  return BLANCO
}

/**
 * Proporción de tinte del fondo: la mayor (hasta 45 %) con la que el texto
 * principal mantiene 7:1 y el secundario 4.5:1 sobre la capa más clara.
 */
function proporcionDeTinte(tinte) {
  const capaMasClara = hexARgb(CAPAS['--gb-surface-highest'])
  for (let proporcion = 0.45; proporcion > 0; proporcion -= 0.05) {
    const capa = mezclar(capaMasClara, tinte, proporcion)
    if (contraste(hexARgb(TEXTO), capa) >= 7 && contraste(hexARgb(TEXTO_SECUNDARIO), capa) >= 4.5) {
      return proporcion
    }
  }
  return 0
}

/**
 * Devuelve `{ '--token': valor }` con lo que hay que escribir en `:root`.
 * Un color ausente o inválido deja sus tokens como en el tema por defecto.
 */
export function calcularTemaEmpresa({ colorFondo, colorAcento } = {}) {
  const variables = {}
  const tinte = hexARgb(colorFondo)
  let fondo = hexARgb(CAPAS['--gb-bg'])
  let superficie = hexARgb(CAPAS['--gb-surface'])

  if (tinte) {
    const proporcion = proporcionDeTinte(tinte)
    for (const [token, valor] of Object.entries(CAPAS)) {
      variables[token] = rgbAHex(mezclar(hexARgb(valor), tinte, proporcion))
    }
    fondo = hexARgb(variables['--gb-bg'])
    superficie = hexARgb(variables['--gb-surface'])
  }

  const acentoElegido = hexARgb(colorAcento)
  if (acentoElegido) {
    // Relleno de botones y bordes: 3:1 sobre el fondo (WCAG 1.4.11).
    const acento = aclararHasta(acentoElegido, fondo, 3)
    const sobreAcento = contraste(BLANCO, acento) >= contraste(NEGRO, acento) ? BLANCO : NEGRO
    // Texto de acento (enlaces, etiquetas): 4.5:1 sobre la tarjeta.
    const textoAcento = aclararHasta(acento, superficie, 4.5)

    variables['--gb-red'] = rgbAHex(acento)
    variables['--gb-red-hover'] = rgbAHex(mezclar(acento, sobreAcento, 0.15))
    variables['--gb-red-rgb'] = acento.map(Math.round).join(', ')
    variables['--gb-on-red'] = rgbAHex(sobreAcento)
    variables['--gb-red-text'] = rgbAHex(textoAcento)
    variables['--gb-link-hover'] = rgbAHex(mezclar(textoAcento, BLANCO, 0.35))
    variables['--gb-focus'] = rgbAHex(textoAcento)
  }

  return variables
}
