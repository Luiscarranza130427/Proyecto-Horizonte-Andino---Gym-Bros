const CLAVE_SESION = 'gym_bros_session'

export function guardarSesion(sesion) {
  try {
    sessionStorage.setItem(CLAVE_SESION, JSON.stringify(sesion))
  } catch (error) {
    console.warn('[Gym Bros] No se pudo persistir la sesión en sessionStorage:', error)
  }
}

export function leerSesion() {
  try {
    const serializado = sessionStorage.getItem(CLAVE_SESION)
    return serializado ? JSON.parse(serializado) : null
  } catch {
    return null
  }
}

export function limpiarSesion() {
  try {
    sessionStorage.removeItem(CLAVE_SESION)
  } catch (error) {
    console.warn('[Gym Bros] No se pudo limpiar la sesión de sessionStorage:', error)
  }
}
