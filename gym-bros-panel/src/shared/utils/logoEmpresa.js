export const LOGO_EMPRESA_ANCHO = 400
export const LOGO_EMPRESA_ALTO = 180
export const LOGO_EMPRESA_TAMANO_MAXIMO = 2 * 1024 * 1024

const TIPOS_PERMITIDOS = new Set(['image/png', 'image/jpeg', 'image/webp'])

function leerComoDataUrl(archivo) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('No se pudo leer el archivo seleccionado.'))
    reader.onload = () => resolve(reader.result)
    reader.readAsDataURL(archivo)
  })
}

function cargarImagen(url) {
  return new Promise((resolve, reject) => {
    const imagen = new Image()
    imagen.onerror = () => reject(new Error('El archivo no contiene una imagen válida.'))
    imagen.onload = () => resolve(imagen)
    imagen.src = url
  })
}

/**
 * Convierte cualquier logo válido al formato horizontal oficial de 400 × 180 px.
 * La imagen se escala con `contain`, se centra y nunca se deforma. El espacio
 * sobrante permanece transparente para funcionar sobre fondos claros u oscuros.
 */
export async function normalizarLogoEmpresa(archivo) {
  if (!archivo) throw new Error('Selecciona un logo.')

  if (!TIPOS_PERMITIDOS.has(archivo.type)) {
    throw new Error('El logo debe ser PNG, JPG o WebP.')
  }

  if (archivo.size > LOGO_EMPRESA_TAMANO_MAXIMO) {
    throw new Error('El logo no puede superar 2 MB.')
  }

  const origen = await leerComoDataUrl(archivo)
  const imagen = await cargarImagen(origen)
  const canvas = document.createElement('canvas')
  canvas.width = LOGO_EMPRESA_ANCHO
  canvas.height = LOGO_EMPRESA_ALTO

  const contexto = canvas.getContext('2d')
  if (!contexto) throw new Error('No se pudo preparar el logo en este navegador.')

  const escala = Math.min(
    LOGO_EMPRESA_ANCHO / imagen.naturalWidth,
    LOGO_EMPRESA_ALTO / imagen.naturalHeight,
  )
  const ancho = Math.round(imagen.naturalWidth * escala)
  const alto = Math.round(imagen.naturalHeight * escala)
  const x = Math.round((LOGO_EMPRESA_ANCHO - ancho) / 2)
  const y = Math.round((LOGO_EMPRESA_ALTO - alto) / 2)

  contexto.clearRect(0, 0, LOGO_EMPRESA_ANCHO, LOGO_EMPRESA_ALTO)
  contexto.imageSmoothingEnabled = true
  contexto.imageSmoothingQuality = 'high'
  contexto.drawImage(imagen, x, y, ancho, alto)

  return canvas.toDataURL('image/webp', 0.92)
}
