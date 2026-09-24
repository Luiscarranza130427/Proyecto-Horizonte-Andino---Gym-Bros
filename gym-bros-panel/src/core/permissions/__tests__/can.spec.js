import { describe, expect, it } from 'vitest'

import { can } from '@/core/permissions/can'
import { PERMISOS } from '@/core/permissions/permissions'
import { ROLES } from '@/core/permissions/roles'

describe('RBAC - can() evaluation', () => {
  it('devuelve false si el usuario es nulo o indefinido', () => {
    expect(can(PERMISOS.USERS_READ, null)).toBe(false)
    expect(can(PERMISOS.USERS_READ, undefined)).toBe(false)
  })

  it('permite cualquier acción a un super_admin', () => {
    const superAdmin = { rol: ROLES.SUPER_ADMIN }
    expect(can(PERMISOS.USERS_DELETE, superAdmin)).toBe(true)
    expect(can(PERMISOS.COMPANIES_MANAGE, superAdmin)).toBe(true)
    expect(can(PERMISOS.BILLING_MANAGE, superAdmin)).toBe(true)
  })

  it('evalúa correctamente los permisos para un tenant_admin', () => {
    const tenantAdmin = { rol: ROLES.TENANT_ADMIN }
    expect(can(PERMISOS.USERS_READ, tenantAdmin)).toBe(true)
    expect(can(PERMISOS.EXERCISES_CREATE, tenantAdmin)).toBe(true)
    expect(can(PERMISOS.COMPANIES_MANAGE, tenantAdmin)).toBe(false)
  })

  it('evalúa permisos de un entrenador', () => {
    const entrenador = { rol: ROLES.TRAINER }
    expect(can(PERMISOS.EXERCISES_CREATE, entrenador)).toBe(true)
    expect(can(PERMISOS.USERS_DELETE, entrenador)).toBe(false)
  })

  it('respeta permisos explícitos provistos por el backend', () => {
    const usuarioPersonalizado = {
      rol: ROLES.MEMBER,
      permisos: [PERMISOS.USERS_READ, PERMISOS.EXERCISES_CREATE],
    }
    expect(can(PERMISOS.USERS_READ, usuarioPersonalizado)).toBe(true)
    expect(can(PERMISOS.EXERCISES_CREATE, usuarioPersonalizado)).toBe(true)
    expect(can(PERMISOS.USERS_DELETE, usuarioPersonalizado)).toBe(false)
  })
})

describe('roles tal como los envía la API (tipo_usuario)', () => {
  it('traduce Administrador, Empresa, Entrenador y Usuario a la matriz', () => {
    // Antes «Administrador» no encajaba en la matriz y perdía el módulo de planes.
    expect(can(PERMISOS.MEMBERSHIPS_MANAGE, { rol: 'Administrador' })).toBe(true)
    expect(can(PERMISOS.COMPANIES_MANAGE, { rol: 'administrador ' })).toBe(true)
    expect(can(PERMISOS.USERS_CREATE, { rol: 'Empresa' })).toBe(true)
    expect(can(PERMISOS.COMPANIES_MANAGE, { rol: 'Empresa' })).toBe(false)
    expect(can(PERMISOS.EXERCISES_CREATE, { rol: 'Entrenador' })).toBe(true)
    expect(can(PERMISOS.USERS_DELETE, { rol: 'Entrenador' })).toBe(false)
    expect(can(PERMISOS.USERS_READ, { rol: 'Usuario' })).toBe(false)
    expect(can(PERMISOS.NUTRITION_READ, { rol: 'Usuario' })).toBe(true)
  })

  it('un rol desconocido cae al mínimo, nunca a un rol con más permisos', () => {
    expect(can(PERMISOS.USERS_READ, { rol: 'SuperHacker' })).toBe(false)
    expect(can(PERMISOS.USERS_READ, { rol: '' })).toBe(false)
  })
})
