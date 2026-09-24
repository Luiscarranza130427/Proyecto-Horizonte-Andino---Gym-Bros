export const BANNER_EMPRESA_ANCHO = 500
export const BANNER_EMPRESA_ALTO = 380
export const BANNER_EMPRESA_TAMANO_MAXIMO = 3 * 1024 * 1024

/** Los tres huecos que guarda `empresas`: `banner_1`, `banner_2` y `banner_3`. */
export const BANNERS_POR_EMPRESA = 3

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
 * Convierte un banner al formato de 500 × 380 px que muestra la app móvil.
 *
 * A diferencia del logo, aquí se recorta (`cover`) en lugar de encajar dentro:
 * un banner con franjas transparentes a los lados se vería roto sobre el fondo
 * de la aplicación. Se escala por el lado que falta y se centra, de modo que la
 * imagen siempre llena el marco y nunca se deforma.
 *
 * Devuelve una cadena `data:` en WebP, que es lo que el backend guarda en
 * `empresas.banner_N`: no hay endpoint de subida de archivos, así que la imagen
 * viaja como texto igual que ya hace el logo.
 */
export async function normalizarBannerEmpresa(archivo) {
  if (!archivo) throw new Error('Selecciona una imagen para el banner.')

  if (!TIPOS_PERMITIDOS.has(archivo.type)) {
    throw new Error('El banner debe ser PNG, JPG o WebP.')
  }

  if (archivo.size > BANNER_EMPRESA_TAMANO_MAXIMO) {
    const megas = Math.round(BANNER_EMPRESA_TAMANO_MAXIMO / 1024 / 1024)
    throw new Error(`El banner no puede superar ${megas} MB.`)
  }

  /*
   * `createImageBitmap` decodifica fuera del hilo principal y NO necesita
   * convertir el archivo a base64 antes. Una foto de móvil de 4000 × 3000 son
   * unos 48 MB de mapa de bits; pasarla antes por una cadena `data:` de varios
   * megas duplicaba el pico de memoria y podía llevarse la pestaña por delante,
   * dejando la pantalla en negro. Se usa el lector clásico sólo si el navegador
   * no lo soporta.
   */
  let imagen
  let liberar = () => {}

  if (typeof createImageBitmap === 'function') {
    imagen = await createImageBitmap(archivo).catch(() => null)
    if (imagen) liberar = () => imagen.close?.()
  }

  if (!imagen) {
    const origen = await leerComoDataUrl(archivo)
    imagen = await cargarImagen(origen)
  }

  const canvas = document.createElement('canvas')
  canvas.width = BANNER_EMPRESA_ANCHO
  canvas.height = BANNER_EMPRESA_ALTO

  const contexto = canvas.getContext('2d')
  if (!contexto) {
    liberar()
    throw new Error('No se pudo preparar el banner en este navegador.')
  }

  // `cover`: se toma la escala MAYOR de las dos para que no quede hueco.
  // Un `ImageBitmap` expone `width`/`height`; un `<img>`, `naturalWidth`. Sin
  // contemplar los dos, la escala salía `NaN` y el banner se dibujaba vacío.
  const anchoOrigen = imagen.naturalWidth || imagen.width
  const altoOrigen = imagen.naturalHeight || imagen.height

  if (!anchoOrigen || !altoOrigen) {
    liberar()
    throw new Error('No se pudieron leer las dimensiones de la imagen.')
  }

  const escala = Math.max(BANNER_EMPRESA_ANCHO / anchoOrigen, BANNER_EMPRESA_ALTO / altoOrigen)
  const ancho = Math.round(anchoOrigen * escala)
  const alto = Math.round(altoOrigen * escala)
  const x = Math.round((BANNER_EMPRESA_ANCHO - ancho) / 2)
  const y = Math.round((BANNER_EMPRESA_ALTO - alto) / 2)

  contexto.clearRect(0, 0, BANNER_EMPRESA_ANCHO, BANNER_EMPRESA_ALTO)
  contexto.imageSmoothingEnabled = true
  contexto.imageSmoothingQuality = 'high'
  contexto.drawImage(imagen, x, y, ancho, alto)
  liberar()

  /*
   * WebP puede no estar disponible: si el navegador no lo admite, `toDataURL`
   * devuelve un PNG sin avisar, y algunos navegadores con protección
   * antihuella —Brave -- pueden negar la lectura del lienzo por completo.
   * Comprobarlo evita guardar una cadena inservible en la base de datos.
   */
  const resultado = canvas.toDataURL('image/webp', 0.9)

  if (!resultado || !resultado.startsWith('data:image/')) {
    throw new Error('Tu navegador no permitió procesar la imagen. Prueba con otro archivo.')
  }

  return resultado
}
