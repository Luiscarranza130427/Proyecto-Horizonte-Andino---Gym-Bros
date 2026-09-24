/**
 * Error normalizado de la capa de datos.
 *
 * Compatible con firmas polimórficas:
 * - new HttpError(status, message, errors)
 * - new HttpError({ status, message, errors, retryAfter })
 */
export class HttpError extends Error {
  constructor(statusOrOptions, message, errors = null) {
    if (typeof statusOrOptions === 'object' && statusOrOptions !== null) {
      super(statusOrOptions.message ?? message ?? '')
      this.name = 'HttpError'
      this.status = statusOrOptions.status ?? 500
      this.errors = statusOrOptions.errors ?? null
      this.retryAfter = statusOrOptions.retryAfter ?? null
    } else {
      super(message ?? '')
      this.name = 'HttpError'
      this.status = Number(statusOrOptions) || 500
      this.errors = errors ?? null
      this.retryAfter = null
    }
  }
}
