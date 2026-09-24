import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import { obtenerTenantActual } from '@/core/tenant/tenant.service'
import { resolverUrlStorage } from '@/shared/utils/storage'

const FAVICON_PREDETERMINADO = '/favicon.svg'

export const useTenantStore = defineStore('tenant', () => {
  const tenant = ref(null)
  const cargando = ref(false)

  const tenantId = computed(() => tenant.value?.id ?? null)
  const nombreTenant = computed(() => tenant.value?.nombre ?? 'Mi Gimnasio')
  const esActivo = computed(() => Boolean(tenant.value?.activo))
  const logoUrl = computed(() => resolverUrlStorage(tenant.value?.logo))
  const colorPrimario = computed(
    () => tenant.value?.color1 || tenant.value?.color_1 || tenant.value?.colorPrimario || null,
  )
  const colorSecundario = computed(
    () => tenant.value?.color2 || tenant.value?.color_2 || tenant.value?.colorSecundario || null,
  )

  function aplicarFaviconEmpresa() {
    if (typeof document === 'undefined') return

    let favicon = document.querySelector('link[rel~="icon"]')
    if (!favicon) {
      favicon = document.createElement('link')
      favicon.rel = 'icon'
      document.head.append(favicon)
    }

    if (logoUrl.value) {
      favicon.removeAttribute('type')
      favicon.setAttribute('href', logoUrl.value)
      return
    }

    favicon.type = 'image/svg+xml'
    favicon.setAttribute('href', FAVICON_PREDETERMINADO)
  }

  function aplicarTemaEmpresa() {
    if (typeof document === 'undefined') return
    // Limpia versiones antiguas que podían haber teñido todo el fondo de la app.
    document.documentElement.style.removeProperty('--gb-bg')
    document.documentElement.style.removeProperty('--gb-text')
    const fondo = colorPrimario.value
    const texto = colorSecundario.value
    if (fondo) {
      document.documentElement.style.setProperty('--gb-tenant-primary', fondo)
      document.documentElement.style.setProperty('--gb-tenant-background', fondo)
    }
    if (texto) {
      document.documentElement.style.setProperty('--gb-tenant-secondary', texto)
      document.documentElement.style.setProperty('--gb-tenant-text', texto)
    }
    aplicarFaviconEmpresa()
  }

  function removerTemaEmpresa() {
    if (typeof document === 'undefined') return
    document.documentElement.style.removeProperty('--gb-tenant-primary')
    document.documentElement.style.removeProperty('--gb-tenant-background')
    document.documentElement.style.removeProperty('--gb-tenant-secondary')
    document.documentElement.style.removeProperty('--gb-tenant-text')
    aplicarFaviconEmpresa()
  }

  async function cargarTenant() {
    cargando.value = true
    try {
      tenant.value = await obtenerTenantActual()
      aplicarTemaEmpresa()
    } catch (error) {
      console.warn('[Gym Bros] No se pudo cargar el contexto de tenant:', error)
      tenant.value = null
      removerTemaEmpresa()
    } finally {
      cargando.value = false
    }
  }

  function fijarTenant(nuevoTenant) {
    tenant.value = nuevoTenant
    aplicarTemaEmpresa()
  }

  function limpiarTenant() {
    tenant.value = null
    removerTemaEmpresa()
  }

  return {
    tenant,
    tenantId,
    nombreTenant,
    logoUrl,
    colorPrimario,
    colorSecundario,
    esActivo,
    cargando,
    cargarTenant,
    fijarTenant,
    limpiarTenant,
  }
})
