const CORREO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function esCorreoValido(valor) {
  return CORREO.test(String(valor ?? '').trim())
}

const TELEFONO = /^\+?[0-9\s-]+$/

export function esTelefonoValido(valor) {
  const telefono = String(valor ?? '').trim()
  const digitos = telefono.replace(/\D/g, '')
  return TELEFONO.test(telefono) && digitos.length >= 7 && digitos.length <= 15
}

/** Quita espacios y guiones: «976 123-456» se guarda como «976123456». */
export function limpiarTelefono(valor) {
  return String(valor ?? '').replace(/[\s-]/g, '')
}

/**
 * Teléfono que cabe en su columna de la API: `empresas.telefono` es
 * varchar(9) y `usuarios.telefono` varchar(12). `esTelefonoValido` admite
 * hasta 15 dígitos con separadores y la API los rechazaba con 422.
 */
export function esTelefonoConLimite(valor, maximo) {
  const limpio = limpiarTelefono(valor)
  return /^\+?\d{6,}$/.test(limpio) && limpio.length <= maximo
}

const COLOR_HEX = /^#[0-9a-f]{6}$/i

export function esColorValido(valor) {
  return COLOR_HEX.test(String(valor ?? ''))
}

export function esUrlValida(valor) {
  try {
    return ['http:', 'https:'].includes(new URL(String(valor)).protocol)
  } catch {
    return false
  }
}

export function esFechaPasada(valor, ahora = new Date()) {
  const instante = new Date(`${valor}T00:00:00`)
  return !Number.isNaN(instante.getTime()) && instante <= ahora
}
