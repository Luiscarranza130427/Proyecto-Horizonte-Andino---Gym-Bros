import { MATRIZ_PERMISOS_ROL, ROLES, normalizarRol } from '@/core/permissions/roles'

/**
 * Evalúa si un usuario cuenta con un permiso determinado según su rol y permisos explícitos.
 *
 * @param {string} permiso
 * @param {object|null} usuario
 * @returns {boolean}
 */
export function can(permiso, usuario = null) {
  if (!usuario) return false

  const rol = normalizarRol(usuario.rol ?? usuario.role)

  // Super Admin siempre tiene acceso total
  if (rol === ROLES.SUPER_ADMIN) return true

  // Permisos explícitos provistos por backend
  if (Array.isArray(usuario.permisos) && usuario.permisos.includes(permiso)) {
    return true
  }

  // Permisos derivados de la matriz de roles
  const permisosRol = MATRIZ_PERMISOS_ROL[rol] ?? []
  return permisosRol.includes(permiso)
}
