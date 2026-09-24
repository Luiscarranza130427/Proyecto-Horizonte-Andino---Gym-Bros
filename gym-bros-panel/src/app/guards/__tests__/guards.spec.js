import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

import { guardAutenticacion } from '@/app/guards/auth.guard'
import { guardPermiso } from '@/app/guards/permission.guard'
import { useAuthStore } from '@/core/auth/auth.store'
import { CREDENCIALES_DEMO } from '@/modules/auth/mocks/auth.mock'

const ruta = (meta, fullPath = '/dashboard') => ({ meta, fullPath })

describe('guardAutenticacion', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()
    setActivePinia(createPinia())
  })

  it('envía al login y recuerda el destino si la ruta exige sesión', () => {
    const resultado = guardAutenticacion(ruta({ requiresAuth: true }))
    expect(resultado).toEqual({ name: 'login', query: { redirect: '/dashboard' } })
  })

  it('deja pasar una ruta pública sin sesión', () => {
    expect(guardAutenticacion(ruta({}, '/404'))).toBe(true)
  })

  it('deja pasar la ruta protegida cuando hay sesión', async () => {
    await useAuthStore().iniciarSesion(CREDENCIALES_DEMO)
    expect(guardAutenticacion(ruta({ requiresAuth: true }))).toBe(true)
  })

  it('saca del login a quien ya tiene sesión', async () => {
    await useAuthStore().iniciarSesion(CREDENCIALES_DEMO)
    expect(guardAutenticacion(ruta({ guestOnly: true }, '/login'))).toEqual({ name: 'dashboard' })
  })
})

describe('guardPermiso', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()
    setActivePinia(createPinia())
  })

  it('permite navegación si la ruta no exige permisos especiales', () => {
    expect(guardPermiso(ruta({}))).toBe(true)
  })

  it('bloquea navegación a 403 si el usuario carece del permiso', () => {
    const auth = useAuthStore()
    auth.usuario = { rol: 'usuario' }
    const resultado = guardPermiso(ruta({ permission: 'companies.manage' }))
    expect(resultado).toEqual({ name: 'forbidden' })
  })
})
