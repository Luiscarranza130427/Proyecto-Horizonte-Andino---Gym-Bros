import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

import { useTenantStore } from '@/core/tenant/tenant.store'

describe('Tenant Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    document.head.innerHTML = '<link rel="icon" type="image/svg+xml" href="/favicon.svg">'
  })

  it('inicia con estado de tenant vacío', () => {
    const store = useTenantStore()
    expect(store.tenant).toBeNull()
    expect(store.tenantId).toBeNull()
    expect(store.nombreTenant).toBe('Mi Gimnasio')
    expect(store.esActivo).toBe(false)
  })

  it('fija y limpia el tenant correctamente', () => {
    const store = useTenantStore()
    store.fijarTenant({ id: 42, nombre: 'Power Gym', activo: true })

    expect(store.tenantId).toBe(42)
    expect(store.nombreTenant).toBe('Power Gym')
    expect(store.esActivo).toBe(true)

    store.limpiarTenant()
    expect(store.tenant).toBeNull()
    expect(store.tenantId).toBeNull()
  })

  it('usa el logo del tenant como favicon y restaura el predeterminado al limpiarlo', () => {
    const store = useTenantStore()
    store.fijarTenant({
      id: 42,
      nombre: 'Power Gym',
      activo: true,
      logo: 'https://cdn.example.com/power-gym.webp',
    })

    const favicon = document.querySelector('link[rel~="icon"]')
    expect(favicon.getAttribute('href')).toBe('https://cdn.example.com/power-gym.webp')
    expect(favicon.hasAttribute('type')).toBe(false)

    store.limpiarTenant()
    expect(favicon.getAttribute('href')).toBe('/favicon.svg')
    expect(favicon.getAttribute('type')).toBe('image/svg+xml')
  })

  it('carga el tenant mock cuando se solicita', async () => {
    const store = useTenantStore()
    await store.cargarTenant()

    expect(store.tenantId).toBe(1)
    expect(store.nombreTenant).toBe('Gym Bros Central')
    expect(store.esActivo).toBe(true)
  })

  it('pinta el panel con los colores de la empresa y los retira al salir', () => {
    const raiz = document.documentElement.style
    const store = useTenantStore()

    store.fijarTenant({ id: 1, nombre: 'Titan Gym', color1: '#111111', color2: '#14ff5b' })
    // El acento del panel (`--gb-red`) pasa a ser el color de la empresa,
    // igual que en la app móvil. Antes sólo cambiaban unos pocos detalles.
    expect(raiz.getPropertyValue('--gb-red')).toBe('#14ff5b')
    expect(raiz.getPropertyValue('--gb-bg')).not.toBe('')
    expect(raiz.getPropertyValue('--gb-tenant-secondary')).toBe('#14ff5b')

    store.limpiarTenant()
    expect(raiz.getPropertyValue('--gb-red')).toBe('')
    expect(raiz.getPropertyValue('--gb-bg')).toBe('')
    expect(raiz.getPropertyValue('--gb-tenant-secondary')).toBe('')
  })

  it('actualiza nombre, logo y colores al guardar la empresa de la sesión', () => {
    const raiz = document.documentElement.style
    const store = useTenantStore()
    store.fijarTenant({ id: 1, nombre: 'Titan Gym', logo: '/logo.webp', color2: '#14ff5b' })

    store.actualizarDesdeEmpresa({ id: 2, nombre: 'Otra', colorSecundario: '#00aeef' })
    expect(raiz.getPropertyValue('--gb-red')).toBe('#14ff5b')

    store.actualizarDesdeEmpresa({ id: 1, nombre: 'Titan Gym Pro', colorSecundario: '#00aeef' })
    expect(store.nombreTenant).toBe('Titan Gym Pro')
    expect(raiz.getPropertyValue('--gb-red')).toBe('#00aeef')
    // Sin logo en la empresa guardada se conserva el que ya tenía el shell.
    expect(store.tenant.logo).toBe('/logo.webp')
  })
})
