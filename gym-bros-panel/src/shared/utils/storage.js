import { API_BASE_URL } from '@/core/config/env'

export function obtenerBackendOrigen() {
  try {
    const url = new URL(
      API_BASE_URL,
      typeof window !== 'undefined' ? window.location?.origin : 'http://localhost',
    )
    return url.origin
  } catch {
    return ''
  }
}

/**
 * Resuelve URLs de archivos públicos de Laravel Storage (fotos, logos, banners).
 * Convierte rutas relativas o de almacenamiento interno de Windows a URLs web accesibles.
 *
 * @param {string} ruta - Ruta devuelta por la API (ej. 'gym-bros\\storage\\app\\public\\empresas\\titan_gym.webp')
 * @returns {string} - URL completa lista para ser consumida en etiquetas <img>
 */
export function resolverUrlStorage(ruta) {
  if (!ruta || typeof ruta !== 'string') return ''

  const limpia = ruta.trim()
  if (!limpia) return ''

  // Si ya es una URL absoluta o formato Data/Blob
  if (
    limpia.startsWith('http://') ||
    limpia.startsWith('https://') ||
    limpia.startsWith('data:') ||
    limpia.startsWith('blob:')
  ) {
    return limpia
  }

  const origen = obtenerBackendOrigen()

  // Normalizar separadores de ruta en Windows
  const normalizada = limpia.replace(/\\/g, '/')

  // Manejar rutas internas tipo storage/app/public/... o .../public/storage/...
  const indicePublic = normalizada.indexOf('public/')
  if (indicePublic !== -1) {
    const relativo = normalizada.substring(indicePublic + 'public/'.length)
    if (relativo.startsWith('storage/')) {
      return `${origen}/${relativo}`
    }
    if (relativo.startsWith('/storage/')) {
      return `${origen}${relativo}`
    }
    return `${origen}/storage/${relativo}`
  }

  // Si empieza con /storage/ o storage/
  if (normalizada.startsWith('/storage/')) {
    return `${origen}${normalizada}`
  }
  if (normalizada.startsWith('storage/')) {
    return `${origen}/${normalizada}`
  }

  // Si empieza por barra simple /
  if (normalizada.startsWith('/')) {
    return `${origen}/storage${normalizada}`
  }

  return `${origen}/storage/${normalizada}`
}
