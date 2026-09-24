export const FOTO_USUARIO_LADO = 256
export const FOTO_USUARIO_TAMANO_MAXIMO = 3 * 1024 * 1024

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
 * Convierte una foto de perfil al cuadrado de 256 × 256 px que usa el avatar.
 *
 * Se recorta (`cover`) por el centro en lugar de encajar dentro: un avatar con
 * franjas transparentes se ve roto dentro de su círculo. 256 px es el doble del
 * tamaño al que se pinta, para que no se vea borroso en pantallas de alta
 * densidad, y sigue pesando poco.
 *
 * Devuelve una cadena `data:` en WebP, que es lo que el backend guarda en
 * `usuarios.foto_perfil`: no hay endpoint de subida de archivos, así que la
 * imagen viaja como texto igual que ya hacen el logo y los banners.
 */
export async function normalizarFotoUsuario(archivo) {
  if (!archivo) throw new Error('Selecciona una imagen para la foto de perfil.')

  if (!TIPOS_PERMITIDOS.has(archivo.type)) {
    throw new Error('La foto debe ser PNG, JPG o WebP.')
  }

  if (archivo.size > FOTO_USUARIO_TAMANO_MAXIMO) {
    const megas = Math.round(FOTO_USUARIO_TAMANO_MAXIMO / 1024 / 1024)
    throw new Error(`La foto no puede superar ${megas} MB.`)
  }

  // `createImageBitmap` decodifica sin pasar el archivo por una cadena base64
  // antes: con una foto de móvil eso duplicaba el pico de memoria.
  let imagen
  let liberar = () => {}

  if (typeof createImageBitmap === 'function') {
    imagen = await createImageBitmap(archivo).catch(() => null)
    if (imagen) liberar = () => imagen.close?.()
  }

  if (!imagen) {
    imagen = await cargarImagen(await leerComoDataUrl(archivo))
  }

  const canvas = document.createElement('canvas')
  canvas.width = FOTO_USUARIO_LADO
  canvas.height = FOTO_USUARIO_LADO

  const contexto = canvas.getContext('2d')
  if (!contexto) {
    liberar()
    throw new Error('No se pudo preparar la foto en este navegador.')
  }

  // Un `ImageBitmap` expone `width`; un `<img>`, `naturalWidth`.
  const anchoOrigen = imagen.naturalWidth || imagen.width
  const altoOrigen = imagen.naturalHeight || imagen.height

  if (!anchoOrigen || !altoOrigen) {
    liberar()
    throw new Error('No se pudieron leer las dimensiones de la imagen.')
  }

  const escala = Math.max(FOTO_USUARIO_LADO / anchoOrigen, FOTO_USUARIO_LADO / altoOrigen)
  const ancho = Math.round(anchoOrigen * escala)
  const alto = Math.round(altoOrigen * escala)

  contexto.clearRect(0, 0, FOTO_USUARIO_LADO, FOTO_USUARIO_LADO)
  contexto.imageSmoothingEnabled = true
  contexto.imageSmoothingQuality = 'high'
  contexto.drawImage(
    imagen,
    Math.round((FOTO_USUARIO_LADO - ancho) / 2),
    Math.round((FOTO_USUARIO_LADO - alto) / 2),
    ancho,
    alto,
  )
  liberar()

  // Algunos navegadores con protección antihuella pueden negar la lectura del
  // lienzo. Comprobarlo evita guardar una cadena inservible.
  const resultado = canvas.toDataURL('image/webp', 0.9)

  if (!resultado || !resultado.startsWith('data:image/')) {
    throw new Error('Tu navegador no permitió procesar la imagen. Prueba con otro archivo.')
  }

  return resultado
}
