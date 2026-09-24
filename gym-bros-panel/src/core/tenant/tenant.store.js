import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import { obtenerTenantActual } from '@/core/tenant/tenant.service'
import { VARIABLES_TEMA, calcularTemaEmpresa } from '@/core/tenant/temaEmpresa'
import { resolverUrlStorage } from '@/shared/utils/storage'

const FAVICON_PREDETERMINADO = '/favicon.svg'
const VARIABLES_EMPRESA = [
  '--gb-tenant-primary',
  '--gb-tenant-background',
  '--gb-tenant-secondary',
  '--gb-tenant-text',
]

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

  function limpiarVariablesTema() {
    const estilo = document.documentElement.style
    // `--gb-text` lo escribían versiones antiguas: se sigue limpiando.
    for (const variable of [...VARIABLES_TEMA, ...VARIABLES_EMPRESA, '--gb-text']) {
      estilo.removeProperty(variable)
    }
  }

  /*
   * Los colores de la empresa pintan el panel igual que la app móvil: `color_1`
   * tiñe el fondo y `color_2` sustituye al rojo de Gym Bros como acento. Antes
   * sólo se guardaban en `--gb-tenant-*`, que casi nada usaba: la app cambiaba
   * de color y el panel seguía rojo.
   */
  function aplicarTemaEmpresa() {
    if (typeof document === 'undefined') return
    limpiarVariablesTema()
    const estilo = document.documentElement.style
    const fondo = colorPrimario.value
    const texto = colorSecundario.value
    if (fondo) {
      estilo.setProperty('--gb-tenant-primary', fondo)
      estilo.setProperty('--gb-tenant-background', fondo)
    }
    if (texto) {
      estilo.setProperty('--gb-tenant-secondary', texto)
      estilo.setProperty('--gb-tenant-text', texto)
    }
    const tema = calcularTemaEmpresa({ colorFondo: fondo, colorAcento: texto })
    for (const [variable, valor] of Object.entries(tema)) {
      estilo.setProperty(variable, valor)
    }
    aplicarFaviconEmpresa()
  }

  function removerTemaEmpresa() {
    if (typeof document === 'undefined') return
    limpiarVariablesTema()
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

  /**
   * Refleja en el shell una empresa recién guardada (forma de
   * `empresas.service`) si es la de la sesión: nombre, logo y colores cambian
   * al instante, sin recargar. Conserva el resto del contexto del tenant.
   */
  function actualizarDesdeEmpresa(empresa) {
    if (!tenant.value || !empresa || Number(empresa.id) !== Number(tenant.value.id)) return
    const cambios = {
      nombre: empresa.nombre,
      logo: empresa.logoUrl,
      color1: empresa.colorPrimario,
      color2: empresa.colorSecundario,
    }
    fijarTenant({
      ...tenant.value,
      ...Object.fromEntries(Object.entries(cambios).filter(([, valor]) => valor)),
    })
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
    actualizarDesdeEmpresa,
    limpiarTenant,
  }
})
