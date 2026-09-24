import { useAuthStore } from '@/core/auth/auth.store'

export function guardAutenticacion(to) {
  const auth = useAuthStore()

  // Ruta privada sin sesión: redirigir a login
  if (to.meta.requiresAuth && !auth.estaAutenticado) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  // Ruta sólo para invitados (login) con sesión abierta: al dashboard
  if (to.meta.guestOnly && auth.estaAutenticado) {
    return { name: 'dashboard' }
  }

  return true
}
