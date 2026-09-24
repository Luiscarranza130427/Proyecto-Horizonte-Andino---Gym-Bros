/**
 * Acceso centralizado y validado a las variables de entorno.
 *
 * Todas las referencias a `import.meta.env` deben pasar por este módulo.
 * Nunca leas `import.meta.env` directamente desde componentes o servicios.
 */

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api'
export const USE_MOCKS = import.meta.env.VITE_USE_MOCKS === 'true'
export const APP_NAME = import.meta.env.VITE_APP_NAME ?? 'Gym Bros'
export const APP_ENV = import.meta.env.MODE ?? 'development'
export const IS_DEV = import.meta.env.DEV ?? false
export const IS_PROD = import.meta.env.PROD ?? false
