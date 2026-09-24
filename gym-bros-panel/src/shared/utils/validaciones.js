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
