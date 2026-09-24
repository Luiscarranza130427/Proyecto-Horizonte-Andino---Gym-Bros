import { HttpError } from '@/core/api/http-error'
import { leerSesion } from '@/core/storage/session.storage'

let obtenerToken = () => {
  const sesion = leerSesion()
  return sesion?.token || null
}

let alDetectarNoAutorizado = () => {}

async function datosDeError(data) {
  if (typeof Blob !== 'undefined' && data instanceof Blob) {
    try {
      return JSON.parse(await data.text())
    } catch {
      return {}
    }
  }

  return data ?? {}
}

export function registrarProveedorDeToken(proveedor) {
  obtenerToken = proveedor
}

export function registrarManejadorNoAutorizado(manejador) {
  alDetectarNoAutorizado = manejador
}

export function configurarInterceptores(axiosInstance) {
  axiosInstance.interceptors.request.use(
    (config) => {
      if (config.data instanceof FormData) {
        // Axios deja que el navegador añada el boundary de multipart/form-data.
        delete config.headers['Content-Type']
      }
      const token = obtenerToken?.()
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
      return config
    },
    (error) => Promise.reject(error),
  )

  axiosInstance.interceptors.response.use(
    (response) => response,
    async (error) => {
      if (error.response?.status === 401) {
        alDetectarNoAutorizado?.()
      }
      const status = error.response?.status ?? 500
      const data = await datosDeError(error.response?.data)
      const message = data.message ?? error.message ?? 'Ha ocurrido un error inesperado.'
      const errors = data.errors ?? null
      const retryAfter = error.response?.headers?.['retry-after'] ?? null

      return Promise.reject(new HttpError({ status, message, errors, retryAfter }))
    },
  )
}
